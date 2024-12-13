module vhttpn

import picohttpparser
import net
import net.http

pub struct VHttpnConnection {
	pub mut:
	pico_req picohttpparser.Request
	socket net.TcpConn
	remote_addr net.Addr
}

fn listen(addr_type net.AddrFamily, addr string, callback fn(mut VHttpnConnection))! {
	//Create server
	mut server := net.listen_tcp(addr_type, addr) or {
		return err
	}

	for {
		//Accept connections
		mut socket := server.accept() or {
			continue
		}

		//Working new connection asynchronously
		go fn [callback, mut socket](){
			defer {
				socket.close() or {}
			}

			//Read request
			mut main_buf := []u8{}
			mut r := -2
			for r == -2 || r == 1024 {
				mut buf := []u8{len: 1024, cap: 1024}

				r = socket.read(mut buf) or {
					return
				}

				main_buf << buf[..r]
			}

			//Parse request
			mut req := picohttpparser.Request{}
			req.parse_request(main_buf.bytestr().trim_space()) or {
				return
			}

			mut preq := VHttpnConnection{
				pico_req: req
				socket: socket
				remote_addr: socket.peer_addr() or {return}
			}

			//Work callback
			callback(mut preq)
		}()
	}
}

pub fn (mut this VHttpnConnection) write_response(code int, content_type string, body string, additional_headers? http.Header)! {
	mut header := additional_headers or {http.Header{}}

	header.delete(http.CommonHeader.content_type)
	header.delete(http.CommonHeader.content_length)

	header.add(http.CommonHeader.content_type, content_type)
	header.add(http.CommonHeader.content_length, body.len.str())

	this.write_response_header(header, code) or {
		return err
	}

	this.raw(body) or {
		return err
	}
}

pub fn (mut this VHttpnConnection) write_response_header(headers http.Header, code int)! {
	mut header := ""

	header += "HTTP/1.1 "+ code.str() +"\r\n"
	header += headers.str() + "\r\n"

	this.raw(header) or {return err}
}

pub fn (mut this VHttpnConnection) close(){
	this.socket.close() or {}
}

pub fn (mut this VHttpnConnection) raw(raw string)! {
	this.socket.write(raw.bytes()) or {return err}
}
