module assuan;

import assuan::proto;
import std::io, std::collections::list, std::sort;

struct AssuanServer
{
	AssuanIO io;
}

<*
@param [&inout] reader "Input stream" 
@param [&inout] writer "Output stream" 
*>
fn AssuanServer* AssuanServer.init(&self, InStream reader, OutStream writer)
{
	*self = { .io = { .r = reader, .w = writer } };
	return self;
}

<*
@param state "Assuan protocol implementation" 
*>
fn void! AssuanServer.serve(&self, AssuanProtocol state = proto::default_proto(), bool debug = false)
{
	char[MAX_LINE_LENGTH + 2] line;

	self.io.writeline("OK", state.greeting())!;

	@pool()
	{
		String cmd, params;
		while SERVE_LOOP: (true)
		{
			String[] resp = self.io.readline(allocator::temp())!.tsplit(" ", 2);
			switch (resp.len)
			{
				case 2: cmd = resp[0]; params = temp_decode(resp[1]);
				case 1: cmd = resp[0]; params = "";
				default: return AssuanError.IO_ERROR?;
			}
			cmd.convert_ascii_to_upper();
			if (debug) io::eprintfn("[serve (%s)] cmd=%s params=%s", resp, cmd, params);
			switch (cmd)
			{
				case "": continue; // just ignore empty input
				case "BYE":  
					(void)self.io.writeline("OK", "closing connection");
					break SERVE_LOOP;
				case "NOP":  
					(void)self.io.writeline("OK");
				case "OPTION":  
					String key = params;
					String value;
					if (try n = params.index_of("="))
					{
						key = params[:n];
						value = params[n+1..];
					}
					else if (params.contains(" "))
					{
						String[] opts = params.tsplit(" ", 2);
						key = opts[0];
						value = opts[1];
					}
					if (catch err = state.set_option(key.trim(), value.trim()))
					{
						String err_str = string::tformat("failed to set option: %s", err);
						self.io.write_error(err_str)!;
					}
					else
					{
						self.io.writeline("OK")!;
					}
				case "HELP":  
					self.helpCmd(state, params)!;
				default:
					CallbackFn handle;
					foreach (h: state.handlers())
					{
						if (h.cmd != cmd) continue;
						handle = h.handle;
						break;
					}

					if (!handle) {
						String err = string::tformat("unknown command: '%s'", cmd);
						self.io.write_error(err)!;
					}
					else
					{
						if (catch err = handle(&self.io, state, params))
						{
							String err_str = string::tformat("error on command %s: %s", cmd, err);
							self.io.write_error(err_str)!;
						}
						else
						{
							self.io.writeline("OK")!;
						}
					}
			}
		}
	};
}

fn int String.compare_to(self, String other)
{
        usz i, n;
        n = $$min(self.len, other.len);
        while (i < n && (self[i] - other[i]) == 0) i++;
        if (i == n) return self.len - other.len;
        return self[i] - other[i];
}

fn void! AssuanServer.helpCmd(&self, AssuanProtocol state, String params) @private
{
	if (params.len)
	{
		foreach (h: state.help())
		{
			if (!params.contains(h.cmd)) continue;
			foreach (text: h.message)
			{
				self.io.write_comment(text)!;
			}
			self.io.writeline("OK")!;
			return;
		}
		@pool()
		{
			String err = string::tformat("no help message found for command: %s", params);
			self.io.write_error(err)!;
		};
	}
	else
	{
		String[*] help_list = { "NOP", "OPTION", "CANCEL", "BYE", "END", "HELP" };

		@pool()
		{
			List(<String>) dict;
			dict.temp_init_with_array(help_list[..]);
			foreach (h: state.handlers())
			{
				if (!dict.contains(h.cmd)) dict.push(h.cmd);
			}
			sort::quicksort(dict);
			foreach (help_str: dict.array_view())
			{
				self.io.write_comment(help_str)!;
			}
		};
	}
}
