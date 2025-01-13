module assuan;

import std::io;
import std::collections::tuple;
import std::collections::list;

def CommandFn = fn void!(AssuanServer *s, String params);

struct AssuanHelp
{
	String cmd;
	String[] message;
}

struct AssuanHandler
{
	String cmd;
	CommandFn handle;
}

struct AssuanServer
{
	AssuanPipe *pipe;
	String greeting;
	Allocator allocator;
}

<*
@param [&inout] pipe "Assuan communication pipe" 
@param [&inout] allocator
*>
fn AssuanServer! AssuanServer.init(&self, AssuanPipe *pipe, String greeting, Allocator allocator)
{
	String s = greeting.len ? greeting : "Pleased to meet your";

	*self = {
		.pipe = pipe,
		.greeting = s.copy(allocator),
		.allocator = allocator,
	};
	return *self;
}

fn void AssuanServer.free(&self)
{
	if (!self.allocator) return;
	self.greeting.free();
}

fn void! AssuanServer.serve(&self, AssuanHandler[] handlers, AssuanHelp[] help = {})
{
	char[MAX_LINE_LENGTH + 2] line;

	self.pipe.writeline("OK", self.greeting)!;

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
			io::eprintfn("[serve (%s)] cmd=%s params=%s", resp, cmd, params);
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
					unreachable("not implemented yet");
				case "HELP":  
					self.helpCmd(params, help)!;
				case "RESET":  
					unreachable("not implemented yet");
					// nextcase;
				default:
					CommandFn handle;
					foreach (h: handlers)
					{
						if (h.cmd != cmd) continue;
						handle = h.handle;
					}

					if (!handle) {
						String err = string::tformat("unknown command: '%s'", cmd);
						self.pipe.write_error(err)!;
					}
					else
					{
						// TODO: more fine-grained error handling.
						handle(self, params)!;
						self.pipe.writeline("OK")!;
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
