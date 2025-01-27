#vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each(1) * blocks();
no_root_location();
no_long_string();
$ENV{TEST_NGINX_SERVROOT} = server_root();
run_tests();

__DATA__
=== TEST 1: IgnoreCIDR defined (no file)
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "1.1.1.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
         index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- request
GET /?a=buibui
--- error_code: 200

=== TEST 1.1: IgnoreCIDR request (no file)
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "1.1.1.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
         index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- request
GET /?a=buibui
--- error_code: 200

=== TEST 1.2: IgnoreCIDR request with X-Forwarded-For allow (no file) 
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "1.1.1.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
         index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- more_headers
X-Forwarded-For: 1.1.1.1
--- request
GET /?a=buibui
--- error_code: 200

=== TEST 1.3: IgnoreCIDR request with X-Forwarded-For deny (no file)
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "1.1.1.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
         index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- more_headers
X-Forwarded-For: 2.2.2.2
--- request
GET /?a=<>
--- error_code: 412

=== TEST 1.4: Verify IgnoreCIDR works
--- user_files
>>> foobar
foobar text
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
MainRule "str:/foobar" "mz:URL" "s:$TRAVERSAL:4" id:123456;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR  "127.0.0.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
     index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- request
GET /foobar
--- error_code: 200


=== TEST 1.5: Verify IgnoreCIDR x.x.x.x./32 is converted to IgnoreIP
--- user_files
>>> foobar
foobar text
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
MainRule "str:/foobar" "mz:URL" "s:$TRAVERSAL:4" id:123456;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR  "127.0.0.1/32";
     DeniedUrl "/RequestDenied";
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
     index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- request
GET /foobar
--- error_code: 200

=== TEST 1.6: IgnoreCIDR request with X-Forwarded-For allow (ipv6)
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "2001:4860:4860::/112";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
     index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- more_headers
X-Forwarded-For: 2001:4860:4860::8888
--- request
GET /?a=<>
--- error_code: 200

=== TEST 1.7: Verify IgnoreCIDR 2001:4860:4860::8888/128 is converted to IgnoreIP
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR "2001:4860:4860::8888/128";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
     index index.html index.htm;
}
location /RequestDenied {
     return 412;
}
--- more_headers
X-Forwarded-For: 2001:4860:4860::8888
--- request
GET /?a=<>
--- error_code: 200

=== TEST 1.8: IgnoreCIDR request inheritance
--- user_files
>>> foobar
foobar text
--- main_config
load_module $TEST_NGINX_NAXSI_MODULE_SO;
--- http_config
include $TEST_NGINX_NAXSI_RULES;
--- config
location / {
     SecRulesEnabled;
     IgnoreCIDR  "127.0.0.0/24";
     DeniedUrl "/RequestDenied";
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;
     root $TEST_NGINX_SERVROOT/html/;
     index index.html index.htm;

     location /foobar {
          BasicRule wl:10;
     }
}
location /RequestDenied {
     return 412;
}
--- request
GET /foobar?a=update/table
--- curl
--- curl_options: --interface 127.0.0.1
--- error_code: 200
