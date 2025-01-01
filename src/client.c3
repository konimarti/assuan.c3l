module assuan;

import std::io;

struct AssuanClient
{
	InStream r;
	OutStream w;
}

<*
@param [&inout] r "InStream to read from Assuan server"
@param [&inout] w "OutStream to Write to Assuan server"
*>
fn AssuanClient*! AssuanClient.init(&self, InStream r, OutStream w)
{
	*self = { .r = r, .w = w };

	// start by reading server's OK
	@pool()
	{
		String line = io::treadline(self.r)!;
		if (!line.starts_with("OK")) return AssuanError.INIT_FAILED?;
	};

	return self;
}

<*
@param [in] cmd "Command to send to the server."
@param [in] params "Parameters to the command."
@param [out] out "Output string contains returned data, if any"
*>
fn void! AssuanClient.run(&self, String cmd, String params = "", DString *out = null)
{
	@pool()
	{
		DString line;
		line.temp_init();
		line.appendf("%s", cmd);
		if (params.len) line.appendf(" %s", escape(params));
		line.append("\n");
		if (line.len() > 1000) return AssuanError.LINE_TOO_LONG?;

		io::printfn("[Client] sending: '%s'", line.str_view());
		io::fprint(self.w, line)!;

		while LOOP: (true)
		{
			String response = io::treadline(self.r)!;
			io::printfn("[Client] receiving: '%s'", response);
			if (!response.len) return AssuanError.IO_ERROR?;

			String resp_tag = response;
			String resp_content;
			if (try n = response.index_of(" "))
			{
				resp_tag = response[:n];
				resp_content = response[n+1..];
			}

			switch (resp_tag)
			{
				case "OK": return;
				case "ERR": return AssuanError.SERVER_ERROR?;
				case "D": if (out) out.append(resp_content);
				default: return AssuanError.UNKNOWN_SERVER_ANSWER?;
			}
		}
	};
}

fn void! AssuanClient.reset(&self) => self.run("RESET");

fn void! AssuanClient.close(&self) 
{
	defer {| (void)self.r.close(); (void)self.w.close(); |};
	return self.run("BYE");
}

