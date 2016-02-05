/**
 * A HTTP plugin for Cordova / Phonegap
 */
package com.raccoonfink.CordovaHTTP;

import java.io.UnsupportedEncodingException;

import java.net.UnknownHostException;
import java.net.URISyntaxException;
import java.net.SocketTimeoutException;
import javax.net.ssl.SSLHandshakeException;

import java.net.URI;
import java.net.URLEncoder;
import java.util.Map;

import org.apache.cordova.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

import com.raccoonfink.CordovaHTTP.HttpRequest;
import com.raccoonfink.CordovaHTTP.HttpRequest.HttpRequestException;
 
public class CordovaHttpDelete extends CordovaHttp implements Runnable {
    public CordovaHttpDelete(String urlString, Map<?, ?> params, Map<String, String> headers, CallbackContext callbackContext) {
        super(urlString, params, headers, callbackContext);
    }
    
    @Override
    public void run() {
        try {
            final URI u = new URI(this.getUrlString());
            final StringBuilder sb = new StringBuilder(u.getQuery() == null? "":u.getQuery());
            for (final Object key : this.getParams().keySet()) {
                final Object value = this.getParams().get(key);
                if (sb.length() > 0) { sb.append("&"); }
                sb.append(URLEncoder.encode(key.toString(), "UTF-8"));
                if (value != null) {
                    sb.append("=").append(URLEncoder.encode(value.toString()));
                }
            }
            final URI updated = new URI(u.getScheme(), u.getAuthority(), u.getPath(), sb.toString(), u.getFragment());
            HttpRequest request = HttpRequest.delete(updated.toString());
            this.setupSecurity(request);
            this.setupTimeouts(request);
            request.acceptCharset(CHARSET);
            request.headers(this.getHeaders());
            //request.form(this.getParams());
            int code = request.code();
            String body = request.body(CHARSET);
            JSONObject response = new JSONObject();
            response.put("status", code);
            if (code >= 200 && code < 300) {
                response.put("data", body);
                this.getCallbackContext().success(response);
            } else {
                response.put("error", body);
                this.getCallbackContext().error(response);
            }
        } catch (JSONException e) {
            this.respondWithError("There was an error generating the response");
        } catch (URISyntaxException e) {
            this.respondWithError("Invalid URL: " + this.getUrlString());
        } catch (UnsupportedEncodingException e) {
            this.respondWithError("Encountered a non-UTF8 invalid parameter.");
        }  catch (HttpRequestException e) {
            if (e.getCause() instanceof UnknownHostException) {
                this.respondWithError(0, "The host could not be resolved");
            } else if (e.getCause() instanceof SSLHandshakeException) {
                this.respondWithError("SSL handshake failed");
            } else if (e.getCause() instanceof SocketTimeoutException) {
                this.respondWithError("Timeout");
            } else {
                this.respondWithError("There was an error with the request");
            }
        }
    }
}
