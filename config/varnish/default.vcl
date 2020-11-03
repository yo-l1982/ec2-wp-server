#
# VCL file for Helsingborg Stad.
#

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.

vcl 4.0;
import directors;
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";
    .connect_timeout = 600s;
    .first_byte_timeout = 600s;
    .between_bytes_timeout = 600s;
}

acl purge {
    "localhost";
    "127.0.0.1";
}

acl upstream_proxy {
    "127.0.0.1";
}

sub vcl_init {

}

sub vcl_recv {
    # Let's encrypt validation.
    if (req.url ~ "\.well\-known") {
        return (pass);
    }

    # Forward user ips
    if (req.restarts == 0) {
        if (client.ip ~ upstream_proxy && req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For = req.http.X-Real-IP;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Skip cache of wp-json #101994
    if (req.url ~ "^/wp-json") {
        return (pass);
    }

    if (req.url ~ "^/autodiscover/autodiscover.xml") {
        return(synth(403,"Not here."));
    }

    # Do purge
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405,"Not allowed."));
        }
        ban("req.url ~ "+req.url);
        return (purge);
    }

    #ONLY HANDLE HTTP METHODS
    if (
        req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PURGE" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "DELETE"
    ) {
        return (pass);
    }

    #GOOGLE URLS
    if (req.url ~ "\?(utm_(campaign|medium|source|term)|adParams|client|cx|eid|fbid|feed|ref(id|src)?|v(er|iew))=") {
        set req.url = regsub(req.url, "\?.*$", "");
    }

    # TRAILING SLASHES
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    #CACHE SEARCHPAGE AS ONE PAGE [WILL ONLY WORK WITH JS-BASED SEARCH ENGINES]
    if (req.http.host ~ "^helsingborg\.se") {
        if(req.url ~ "^/\?s=") {
            set req.url = regsub(req.url, "(\?)(s)=[+%.-_A-z0-9\s]+&?", "?s=");
        }
    }

    # Some generic cookie manipulation, useful for all templates that follow
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Remove the wp-settings-1 cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");

    # Remove the wp-settings-time-1 cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");

    # Remove cookie consent cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "cookie-consent=[^;]+(; )?", "");

    # Remove any Google Analytics based cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

    # Remove other fe cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "vngage.lkvt=[^;]+(; )?", "");

    # Remove DoubleClick offensive cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");

    # Remove the Quant Capital cookies (added by some plugin, all __qca)
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

    # Remove the AddThis cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");

    # Remove other funky smelling cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "gsScrollPos.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "twsessid.=[^;]+(; )?", "");

    # Remove a ";" prefix in the cookie if present
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

    # Are there cookies left with only spaces or that are empty?
    if (req.http.cookie ~ "^\s*$") {
        unset req.http.cookie;
    }

    # Normalize Accept-Encoding header
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|svg)$") {
            unset req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # Remove all cookies for static files and do not cache them
    if (req.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|otf|ogg|ogm|opus|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        unset req.http.cookie;
        set req.url = regsub(req.url, "\?.*$", "");
        return(pass);
    }

    # Ignore campaign links
    if (req.url ~ "\?(utm_(campaign|medium|source|term)|adParams|client|cx|eid|fbid|feed|ref(id|src)?|v(er|iew))=") {
        set req.url = regsub(req.url, "\?.*$", "");
    }

    # Pass for login & admin pages
    if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
        return (pass);
    }

    # Send Surrogate-Capability headers to announce ESI support to backend
    set req.http.Surrogate-Capability = "key=ESI/1.0";

    # Cookie control
    if (req.http.cookie) {

        #For split testing purposes
        if (req.http.cookie ~ "split_test") {
            return(pipe);
        }

        if (req.http.cookie ~ "(wordpress_)") { #|wp-settings-
            return(pass);
        } else {
            unset req.http.cookie;
        }
    }

    # Authorization not cachable
    if (req.http.Authorization) {
        return (pass);
    }

}

sub vcl_hash {
    if (client.ip ~ upstream_proxy && req.http.X-Forwarded-Proto) {
        hash_data(req.http.X-Forwarded-Proto);
    }
    if (req.http.X-Forwarded-Proto) {
    hash_data(req.http.X-Forwarded-Proto);
    }
}

sub vcl_backend_response {

    #Do not cache wp-admin. Ever. Cache everything else
    if ((!(bereq.url ~ "(wp-(login|admin|json)|login)"))) {
        unset beresp.http.set-cookie;
        set beresp.ttl = 1h;
    }

    # Let's cache images a year or something like that. And oh, enable ESI includes on everything else.
    if (bereq.url ~ "\.(gif|jpg|jpeg|swf|ttf|css|js|flv|mp3|mp4|pdf|ico|png)(\?.*|)$") {
        set beresp.ttl = 365d;
    } else {
        set beresp.do_esi = true;
    }

}

sub vcl_deliver {

    #TELL IF CACHE DELIVER
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    #Allow cross origins
    set resp.http.Access-Control-Allow-Origin = "*";

    #Custom messages
    set resp.http.Helsingborg = "Hi developer! Questions? Contact: sebastian.thulin@helsingborg.se";

    set resp.http.X-Cache-Hits = obj.hits;

    #Remove some headers: PHP version
    unset resp.http.X-Powered-By;

    #Remove some headers: Apache version & OS
    unset resp.http.Server;
    unset resp.http.X-Drupal-Cache;
    unset resp.http.X-Varnish;
    unset resp.http.Via;
    unset resp.http.Link;
    unset resp.http.X-Generator;

}

sub vcl_hit {

    if (req.method == "PURGE") {
        return(synth(200,"OK"));
    }

    if (obj.ttl >= 0s) {
        return (deliver);
    }

    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
        # Backend is healthy. Limit age to 10s.
        if (obj.ttl + 10s > 0s) {
            #set req.http.grace = "normal(limited)";
            return (deliver);
        } else {
            # No candidate for grace. Fetch a fresh object.
            return(miss);
        }
    } else {
        # backend is sick - use full grace
        if (obj.ttl + obj.grace > 0s) {
            #set req.http.grace = "full";
            return (deliver);
        } else {
            # no graced object.
            return (miss);
        }
    }

    # fetch & deliver once we get the result
    return (miss); # Dead code, keep as a safeguard

}

sub vcl_miss {
    if (req.method == "PURGE") {
        return(synth(404,"Not cached"));
    }
}

sub vcl_synth {
    if (resp.status == 720) {
        # We use this special error status 720 to force redirects with 301 (permanent) redirects
        # To use this, call the following from anywhere in vcl_recv: return (synth(720, "http://helsingborg.se"));
        set resp.http.Location = resp.reason;
        set resp.status = 301;
        return (deliver);
    } elseif (resp.status == 721) {
        # And we use error status 721 to force redirects with a 302 (temporary) redirect
        # To use this, call the following from anywhere in vcl_recv: return (synth(720, "http://helsingborg.se"));
        set resp.http.Location = resp.reason;
        set resp.status = 302;
        return (deliver);
    }
    return (deliver);
}

sub vcl_fini {
    return (ok);
}