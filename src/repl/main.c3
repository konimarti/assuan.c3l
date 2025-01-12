module repl;

import std::io;
import std::thread;

import assuan;

fn void main()
{
	AssuanPipe pipe;
	pipe.init(io::stdin(),io::stdout());

	AssuanServer server;
	server.init(&pipe, "Pleased to meet you, REPL!", allocator::heap())!!;
	defer server.free();

	if (catch err = server.serve({},{}))
	{
		io::printfn("server thread stopped: %s", err);
	}
}
