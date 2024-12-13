# VHttpNSrv

VHttpNSrv — минималистичная библиотека для создания HTTP-сервера на языке программирования VLang.

## Пример использования
<b>Пример простого HTTP-сервера, отвечающего "Hello World!" на каждый запрос:</b>

_передаем `none` вместо заголовков ибо тут они не нужны_

```v
module main

import net
import vhttpn

fn main() {
    vhttpn.listen(net.AddrFamily.ip, "0.0.0.0:8080", fn (mut conn vhttpn.VHttpnConnection) {
        conn.write_response(200, "text/plain", "Hello World!", none) or {
            println(err)
        }
    }) or {
        println(err)
    }
}
```

<b>Пример с использованием дополнительных заголовков:</b>

```v
module main

import net
import vhttpn
import net.http

fn main(){
	vhttpn.listen(net.AddrFamily.ip, "0.0.0.0:8080", fn (mut conn VHttpnConnection){
		headers := http.new_header_from_map({
			http.CommonHeader.set_cookie: "my_cookie=data;",
			http.CommonHeader.server: "My V Server"
		})

		conn.write_response(200, "text/plain", "Hello World!", headers) or {
			println(err)
		}
	}) or {
		println(err)
	}
}
```

## API Info:

```vlang
pub struct VHttpnConnection { // объект HTTP соединения
	pub mut:
	pico_req    picohttpparser.Request // Обработанные данные запроса с помощью picohttpparser (Встроен в vlib)
	socket      net.TcpConn // Tcp сокет
	remote_addr net.Addr // Адрес клиента
}
```

```v
// Отправка полноценного ответа.
// additional_headers - Заголовки из встроенной библиотеки vlib -> http
pub fn (mut this VHttpnConnection) write_response(code int, content_type string, body string, additional_headers? http.Header)!
```

```v
// Отправка только заголовка
// headers - Заголовки из встроенной библиотеки vlib -> http
pub fn (mut this VHttpnConnection) write_response_header(headers http.Header, code int)!
```

```v
// Отправка RAW
pub fn (mut this VHttpnConnection) raw(raw string)!
```

```v
// Закрывает соединение
pub fn (mut this VHttpnConnection) close()
```
