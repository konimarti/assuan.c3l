module repl;

import std::io;
import std::thread;

import assuan;

fn void main()
{
	AssuanPipe pipe;
	pipe.init(io::stdin(),io::stdout());

	AssuanServer server;
	server.init(&pipe);

	if (catch err = server.serve(debug: true))
	{
		io::printfn("server thread stopped: %s", err);
	}
}
