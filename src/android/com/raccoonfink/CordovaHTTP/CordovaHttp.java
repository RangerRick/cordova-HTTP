/**
 * A HTTP plugin for Cordova / Phonegap
 */
package com.raccoonfink.CordovaHTTP;

import org.apache.cordova.CallbackContext;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.HostnameVerifier;

import java.util.Iterator;

import android.util.Log;

import com.raccoonfink.CordovaHTTP.HttpRequest;
import com.raccoonfink.CordovaHTTP.HttpRequest.HttpRequestException;

public abstract class CordovaHttp {
    protected static final String TAG = "CordovaHTTP";
    protected static final String CHARSET = "UTF-8";

    private static AtomicBoolean sslPinning = new AtomicBoolean(false);
    private static AtomicBoolean acceptAllCerts = new AtomicBoolean(false);
    private static AtomicInteger connectionTimeout = new AtomicInteger(0);
    private static AtomicInteger readTimeout = new AtomicInteger(0);

    private String urlString;
    private Map<?, ?> params;
    private Map<String, String> headers;
    private Object data;
    private CallbackContext callbackContext;

    public CordovaHttp(final String urlString, final Map<?, ?> params, final Map<String, String> headers, final CallbackContext callbackContext) {
        this(urlString, params, headers, callbackContext, null);
    }

    public CordovaHttp(final String urlString, final Map<?, ?> params, final Map<String, String> headers, final CallbackContext callbackContext, final Object data) {
        this.urlString = urlString;
        this.params = params;
        this.headers = headers;
        this.callbackContext = callbackContext;
        this.data = data;
    }

    public static void enableSSLPinning(boolean enable) {
        sslPinning.set(enable);
        if (enable) {
            acceptAllCerts.set(false);
        }
    }

    public static void acceptAllCerts(boolean accept) {
        acceptAllCerts.set(accept);
        if (accept) {
            sslPinning.set(false);
        }
    }
    public static void setTimeouts(int cTimeout, int rTimeout) {
        connectionTimeout.set(cTimeout);
        readTimeout.set(rTimeout);
    }

    protected String getUrlString() {
        return this.urlString;
    }

    protected Map<?, ?> getParams() {
        return this.params;
    }

    protected Map<String, String> getHeaders() {
        return this.headers;
    }

    protected CallbackContext getCallbackContext() {
        return this.callbackContext;
    }

    protected Object getData() {
        return this.data;
    }

    protected HttpRequest setupSecurity(HttpRequest request) {
        if (acceptAllCerts.get()) {
            request.trustAllCerts();
            request.trustAllHosts();
        }
        if (sslPinning.get()) {
            request.pinToCerts();
        }
        return request;
    }

    protected HttpRequest setupTimeouts(HttpRequest request) {
        request.connectTimeout(connectionTimeout.get());
        request.readTimeout(readTimeout.get());

        return request;
    }

    protected void respondWithError(int status, String msg) {
        try {
            JSONObject response = new JSONObject();
            response.put("status", status);
            response.put("error", msg);
            this.callbackContext.error(response);
        } catch (JSONException e) {
            this.callbackContext.error(msg);
        }
    }

    protected void respondWithError(String msg) {
        this.respondWithError(500, msg);
    }
}
