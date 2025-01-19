module pinentryc3;

import std::io, std::collections::map, libc;
import assuan;

def Options = HashMap(<String, String>);

struct Pinentry (AssuanProtocol)
{
	AssuanHelp[] 	help_messages;
	AssuanHandler[] callbacks;
	Options 	options;
	String		description;
	String		prompt;
}

macro String canonicalize(String key)
{
	key.convert_ascii_to_upper();
	return key;
}

fn String Pinentry.greeting(&self) @dynamic => "Pleased to meet you (pinentry-c3)";
fn AssuanHelp[] Pinentry.help(&self) @dynamic => self.help_messages;
fn AssuanHandler[] Pinentry.handlers(&self) @dynamic => self.callbacks;
fn void! Pinentry.set_option(&self, String key, String value) @dynamic => (void)self.options.set(canonicalize(key), value);

fn void main()
{
	AssuanServer server;
	server.init(io::stdin(), io::stdout());

	Pinentry pin = {
		.help_messages = {},
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
				"SETPROMPT",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					Pinentry *p = (Pinentry*)state;
					p.prompt = params;
				}
			},
			{
				"SETDESC",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					Pinentry *p = (Pinentry*)state;
					p.description = params;
				}
			},
			{
				"SETTITLE", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETREPEAT", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETREPEATERROR", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETERROR", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETOK", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETNOTOK", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETCANCEL", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETQUALITYBAR", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETTIMEOUT", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"SETKEYINFO", fn void!(AssuanIO *io, AssuanProtocol state, String params) { /* ignore for now */ }
			},
			{
				"GETINFO",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					// TODO: handle 'flavor', 'version', 'ttyinfo', 'pid'
					io.write_data("1")!;
				}
			},
			{
				"GETPIN",
				fn void!(AssuanIO *io, AssuanProtocol state, String params)
				{
					((Pinentry*)state).getpin(io, params)!;
				}
			},
		},
		.options = *Options{}.new_init(),
	};
	defer pin.options.free();

	if (catch err = server.serve(state: &pin, debug: false))
	{
		io::printfn("server stopped with error: %s", err);
	}
}

fn void! Pinentry.getpin(&self, AssuanIO *io, String params)
{
	File fo, fi;
	bool use_stdio;
	Termios save, use;
	CInt ttyfi;

	// use the tty set by the TTYNAME option; it no tty was specified, fall
	// back to stdin and stdout;
	String ttyname = self.options["TTYNAME"] ?? "";
	use_stdio = ttyname.len == 0;

	fo = (use_stdio) ? *io::stdout() : file::open(ttyname, "w")!; 
	defer if (!use_stdio) (void)fo.close();

	fi = (use_stdio) ? *io::stdin() : file::open(ttyname, "r")!;
	defer if (!use_stdio) (void)fi.close();

	// print description and prompt
	io::fprint(&fo, "\n")!;

	if (!self.description) self.description = "pinentry-c3";
	io::fprintf(&fo, "%s\n", self.description)!;

	if (!self.prompt) self.prompt = "PIN:";
	io::fprintf(&fo, "%s ", self.prompt)!;

	fo.flush()!!;

	// set terminal to password mode (no echo)
	ttyfi = libc::fileno(fi.file);

	save.getAttr(ttyfi);
	defer save.setAttr(ttyfi, termios::TCSANOW);

	use = save;
	use.c_lflag &= ~(termios::ECHO | termios::ECHOE | termios::ECHOK | termios::ECHONL);
	use.setAttr(ttyfi, termios::TCSAFLUSH);

	// read password
	@pool()
	{
		String passphrase = io::treadline(&fi)!;
		io::fprint(&fo, "\n")!;
		io.write_data(passphrase)!;
	};
}
