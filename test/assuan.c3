module assuan_test;

import assuan;
import std::collections::tuple;

fn void! test_escape() @test
{
	Tuple(<String, String>)[*] tests = {
		{"hello world", "hello world"},
		{"hello\nworld", "hello%0Aworld"},
		{"hello\rworld", "hello%0Dworld"},
		{"hello%world", "hello%25world"},
		{"hello\\world", "hello%5Cworld"},
		{"\r\n%\\", "%0D%0A%25%5C"},
		{"foobar\\", "foobar%5C"},
	};

	String got;
	@pool()
	{
		foreach (i, t: tests)
		{
			got = assuan::tescape(t.first);
			assert(got == t.second,
				"[tescape %d/%d]   got: %s, want: %s", i, tests.len, got, t.second);

			got = assuan::tunescape(t.second);
			assert(got == t.first,
				"[tunescape %d/%d] got: %s, want: %s", i, tests.len, got, t.first);
		}
	};
}

