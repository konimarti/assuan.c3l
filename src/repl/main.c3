module repl;

import std::io;
import assuan;

fn void main()
{
	AssuanServer server;
	server.init(io::stdin(),io::stdout());

	if (catch err = server.serve(debug: true))
	{
		io::printfn("server stopped: %s", err);
	}
}
