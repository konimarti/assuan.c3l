module assuan;

import std::io;
import assuan::proto;

struct AssuanServer
{
	AssuanPipe *pipe;
}

<*
@param [&inout] pipe "Assuan communication pipe" 
*>
fn AssuanServer* AssuanServer.init(&self, AssuanPipe *pipe)
{
	*self = { .pipe = pipe };
	return self;
}

<*
@param state "Assuan protocol implementation" 
*>
fn void! AssuanServer.serve(&self, AssuanProtocol state = proto::default_proto(), bool debug = false)
{
	char[MAX_LINE_LENGTH + 2] line;

	self.pipe.writeline("OK", state.greeting())!;

	@pool()
	{
		String cmd, params;
		while SERVE_LOOP: (true)
		{
			String[] resp = self.pipe.readline(allocator::temp())!.tsplit(" ", 2);
			switch (resp.len)
			{
				case 2: cmd = resp[0]; params = resp[1];
				case 1: cmd = resp[0]; params = "";
				default: return AssuanError.IO_ERROR?;
			}
			if (debug) io::eprintfn("[serve (%s)] cmd=%s params=%s", resp, cmd, params);
			cmd.convert_ascii_to_upper();
			switch (cmd)
			{
				case "": continue; // just ignore empty input
				case "BYE":  
					(void)self.pipe.writeline("OK");
					break SERVE_LOOP;
				case "NOP":  
					(void)self.pipe.writeline("OK");
				case "OPTION":  
					if (try n = params.index_of("="))
					{
						String key = ((String)params[:n]).trim();
						String value = ((String)params[n+1..]).trim();
						if (catch err = state.set_option(key, value))
						{
							String err_str = string::tformat("failed to set option: %s", err);
							self.pipe.write_error(err_str)!;
						}
					}
					else
					{
						self.pipe.write_error("invalid option: no '=' found")!;
					}
				case "HELP":  
					self.helpCmd(params, state.help())!;
				case "RESET":  
					unreachable("not implemented yet");
					// nextcase;
				default:
					CommandFn handle;
					foreach (h: state.handlers())
					{
						if (h.cmd != cmd) continue;
						handle = h.handle;
						break;
					}

					if (!handle) {
						String err = string::tformat("unknown command: '%s'", cmd);
						self.pipe.write_error(err)!;
					}
					else
					{
						if (catch err = handle(self, params))
						{
							String err_str = string::tformat("error on command %s: %s", cmd, err);
							self.pipe.write_error(err_str)!;
						}
						else
						{
							self.pipe.writeline("OK")!;
						}
					}
			}
		}
	};
}

fn void! AssuanServer.helpCmd(&self, String params, AssuanHelp[] help) @private
{
	if (params.len)
	{
		foreach (h: help)
		{
			if (!params.contains(h.cmd)) continue;
			foreach (text: h.message)
			{
				self.pipe.write_comment(text)!;
			}
			self.pipe.writeline("OK")!;
			return;
		}
		@pool()
		{
			String err = string::tformat("no help message found for command: %s", params);
			self.pipe.write_error(err)!;
		};
	}
	else
	{
		String[*] help_list = { "NOP", "OPTION", "CANCEL", "BYE", "RESET", "END", "HELP" };
		foreach (h: help_list) self.pipe.write_comment(h)!;
		foreach (h: help) self.pipe.write_comment(h.cmd)!;
		self.pipe.writeline("OK")!;
	}
}
