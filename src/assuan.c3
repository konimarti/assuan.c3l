module assuan;

fault AssuanError
{
	INIT_FAILED,
	LINE_TOO_LONG,
	IO_ERROR,
	SERVER_ERROR,
	UNKNOWN_SERVER_ANSWER,
}

// tescape allocates the escaped string with the temp allocator.
fn String tescape(String s)
{
	DString tmp = dstring::temp_new(s);
	tmp.replace("%", "%25"); // should be first
	tmp.replace("\r", "%0D");
	tmp.replace("\n", "%0A");
	tmp.replace("\\", "%5C");
	return tmp.str_view();
}

// tunescape allocates the unescaped string with the temp allocator.
fn String tunescape(String s)
{
	DString tmp = dstring::temp_new(s);
	tmp.replace("%0D", "\r");
	tmp.replace("%0A", "\n");
	tmp.replace("%5C", "\\");
	tmp.replace("%25", "%"); // should be last
	return tmp.str_view();
}

