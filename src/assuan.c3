module assuan;

fault AssuanError
{
	INIT_FAILED,
	LINE_TOO_LONG,
	IO_ERROR,
	SERVER_ERROR,
	UNKNOWN_SERVER_ANSWER,
}

// @TODO: to be implemented
fn String escape(String s) => s;

// @TODO: to be implemented
fn String unescape(String s) => s;

