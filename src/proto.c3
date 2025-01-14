module assuan::proto;

def CommandFn = fn void!(AssuanServer *s, String params);

struct AssuanHelp
{
	String cmd;
	String[] message;
}

struct AssuanHandler
{
	String cmd;
	CommandFn handle;
}
interface AssuanProtocol
{
	fn String greeting();
	fn AssuanHelp[] help();
	fn AssuanHandler[] handlers();
	fn void! set_option(String key, String value);
}

distinct AssuanDefaultProto (AssuanProtocol) = String;
fn String AssuanDefaultProto.greeting(&self) @dynamic => (String)*self;
fn AssuanHelp[] AssuanDefaultProto.help(&self) @dynamic => {};
fn AssuanHandler[] AssuanDefaultProto.handlers(&self) @dynamic => {};
fn void! AssuanDefaultProto.set_option(&self, String key, String value) @dynamic {}

AssuanDefaultProto _default = "Pleased to meet you!";

fn AssuanProtocol default_proto() => &_default;
