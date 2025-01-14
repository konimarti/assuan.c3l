module pinentryc3;

import std::io;
import std::collections::map;
import libc;

import assuan;

def Options = HashMap(<String, String>);

struct Pinentry (AssuanProtocol)
{
	AssuanHelp[] 	help_messages;
	AssuanHandler[] callbacks;
	Options 	options;
}

fn String Pinentry.greeting(&self) @dynamic => "Pleased to meet you (pinentry-c3)";
fn AssuanHelp[] Pinentry.help(&self) @dynamic => self.help_messages;
fn AssuanHandler[] Pinentry.handlers(&self) @dynamic => self.callbacks;
fn void! Pinentry.set_option(&self, String key, String value) @dynamic => (void)self.options.set({|key.convert_ascii_to_upper(); return key;|}, value);

fn void main()
{
	AssuanIO pipe;
	pipe.init(io::stdin(),io::stdout());

	AssuanServer server;
	server.init(&pipe);

	Options opt;
	opt.new_init();
	defer opt.free();

	Pinentry pin = {
		.help_messages = { 
			{
				"HELP", {"this is a help message.", "and one on another line"}
			},
		},
		.callbacks = {
			{
				"RESET",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					Pinentry *p = (Pinentry*)state;
					p.options.clear();
				}
			},
			{
				"BOOM",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					Pinentry *p = (Pinentry*)state;
					uint repeat = p.options["REPEAT"]!.to_uint()!;
					for (usz i = 0; i < repeat; i++) io::printn("BOOM!");
				}
			},
			{
				"GETPIN",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					Pinentry *p = (Pinentry*)state;
					String ttyname = p.options["TTYNAME"]!;

					File fo = file::open(ttyname, "w")!;
					defer (void)fo.close();

					File fi = file::open(ttyname, "r")!;
					defer (void)fi.close();
					CInt ttyfi = libc::fileno(fi.file);

					io::fprintf(&fo, "Enter Pin1: ")!;
					fo.flush()!!;

					Termios save;
					save.getAttr(ttyfi);
					defer save.setAttr(ttyfi, termios::TCSANOW);

					Termios use = save;
					use.c_lflag &= ~(termios::ECHO | termios::ECHOE | termios::ECHOK | termios::ECHONL);
					use.setAttr(ttyfi, termios::TCSAFLUSH);

					String passphrase = io::readline(&fi)!;

					io.write_data(passphrase)!;
				}
			},
		},
		.options = opt,
	};

	if (catch err = server.serve(state: &pin, debug: true))
	{
		io::printfn("server stopped with error: %s", err);
	}
}
