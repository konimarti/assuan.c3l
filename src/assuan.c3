module assuan;

import std::io;

fault AssuanError
{
	INIT_FAILED,
	LINE_TOO_LONG,
	IO_ERROR,
	SERVER_ERROR,
	UNKNOWN_SERVER_ANSWER,
	CANCELLED,
}

const int MAX_LINE_LENGTH = 1000;

struct AssuanPipe
{
	InStream r;
	OutStream w;
}

<*
@param [&inout] r "InStream to read from Assuan server"
@param [&inout] w "OutStream to Write to Assuan server"
*>
fn AssuanPipe AssuanPipe.init(&self, InStream r, OutStream w)
{
	*self = { .r = r, .w = w };
	return *self;
}

fn String[]! AssuanPipe.readline(&self, Allocator allocator)
{
	@pool(allocator)
	{
		String r = io::treadline(self.r)!;
		if (!r.len) return AssuanError.IO_ERROR?;
		return r.split(" ", 2, allocator);
	};
}

fn usz! AssuanPipe.writeline(&self, String cmd, String params = "")
{
	@pool()
	{
		DString line;
		line.temp_init();
		line.appendf("%s", cmd);

		if (params.len)
		{
			line.appendf(" %s", temp_decode(params));
		}

		line.append("\n");

		if (line.len() > MAX_LINE_LENGTH) return AssuanError.LINE_TOO_LONG?;

		// io::printfn("assuan::writeline: '%s'", line.str_view());
		return self.w.write(line.str_view());
	};

}

fn usz! AssuanPipe.write_data(&self, char[] data)
{		
	usz n;
	@pool()
	{
		String encoded = temp_encode((String)data);
		while (encoded.len)
		{
			usz len = min(MAX_LINE_LENGTH - 3, encoded.len);
			n += self.writeline("D", encoded[:len])!;
			encoded = encoded[len..];
		}
	};
	return n;
}

fn String! AssuanPipe.read_data(&self, Allocator allocator)
{
	@pool(allocator)
	{
		DString data;
		data.temp_init();

		while READ_LOOP: (true)
		{
			String[] resp = self.readline(allocator::temp())!;
			if (!resp.len) return AssuanError.IO_ERROR?;
			switch (resp[0])
			{
				case "END": return data.copy_str(allocator);
				case "CAN": return AssuanError.CANCELLED?;
				case "D":
					if (resp.len == 2)
					{
						data.append(temp_decode(resp[1]));
					}
					else
					{
						return AssuanError.IO_ERROR?;
					}
				default: return AssuanError.IO_ERROR?;
			}
		}
	};
}

fn usz! AssuanPipe.write_comment(&self, String text) @inline => self.writeline("#", text);
fn usz! AssuanPipe.write_error(&self, String err) @inline => self.writeline("ERR", err);

// temp_encode allocates the escaped string with the temp allocator.
fn String temp_encode(String s)
{
	DString tmp = dstring::temp_new(s);
	tmp.replace("%", "%25"); // should be first
	tmp.replace("\r", "%0D");
	tmp.replace("\n", "%0A");
	tmp.replace("\\", "%5C");
	return tmp.str_view();
}

// temp_decode allocates the unescaped string with the temp allocator.
fn String temp_decode(String s)
{
	DString tmp = dstring::temp_new(s);
	tmp.replace("%0D", "\r");
	tmp.replace("%0A", "\n");
	tmp.replace("%5C", "\\");
	tmp.replace("%25", "%"); // should be last
	return tmp.str_view();
}

