module repl;

import std::io;
import assuan;

fn void main()
{
	AssuanIO io;
	io.init(io::stdin(),io::stdout());

	AssuanServer server;
	server.init(&io);

	if (catch err = server.serve(debug: true))
	{
		io::printfn("server stopped: %s", err);
	}
}
