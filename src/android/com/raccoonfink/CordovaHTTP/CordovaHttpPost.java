/**
 * A HTTP plugin for Cordova / Phonegap
 */
package com.raccoonfink.CordovaHTTP;

import java.net.UnknownHostException;
import java.util.Map;
import java.net.SocketTimeoutException;

import org.apache.cordova.CallbackContext;
import org.json.JSONException;
import org.json.JSONObject;

import javax.net.ssl.SSLHandshakeException;

import android.util.Log;

import com.raccoonfink.CordovaHTTP.HttpRequest;
import com.raccoonfink.CordovaHTTP.HttpRequest.HttpRequestException;

public class CordovaHttpPost extends CordovaHttp implements Runnable {
    public CordovaHttpPost(final String urlString, final Map<?, ?> params, final Map<String, String> headers, final CallbackContext callbackContext) {
        super(urlString, params, headers, callbackContext);
    }

    public CordovaHttpPost(final String urlString, final Map<?, ?> params, final Map<String, String> headers, final CallbackContext callbackContext, final Object data) {
        super(urlString, params, headers, callbackContext, data);
    }

    @Override
    public void run() {
        try {
            HttpRequest request = HttpRequest.post(this.getUrlString());
            this.setupSecurity(request);
            this.setupTimeouts(request);
            request.acceptCharset(CHARSET);

            final Map<String,String> headers = this.getHeaders();
            request.headers(headers);
            if (headers.containsKey("Content-Type") && "application/json".equals(headers.get("Content-Type"))) {
                final String body = this.getData() == null? "" : this.getData().toString();
                request.send(body);
            } else {
                request.form(this.getParams());
            }
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
