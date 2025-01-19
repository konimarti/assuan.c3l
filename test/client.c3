module assuan_tests;

import std::io;
import assuan;

fn void test_client_run() @test
{
	char[128] read;
	ByteBuffer buf;
	buf.init_with_buffer(read[..])!!;

	io::fprint(&buf, "OK Pleased to meet you\n")!!;
	io::fprint(&buf, "D ABCDE\n")!!;
	io::fprint(&buf, "OK\n")!!;

	char[32] write;
	AssuanIO io = { 
		.r = &buf,
		.w = ByteWriter{}.init_with_buffer(write[..]),
	};

	AssuanClient c;
	c.init(io)!!;

	@pool()
	{
		DString out;
		out.temp_init();
		c.run("TESTCMD", "PARAMS_123", &out)!!;
		assert(out.str_view() == "ABCDE", "got: %s, want: %s", out.str_view(), "ABCDE");
	};
}
