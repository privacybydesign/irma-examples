package com.example.irmaandroiddemoapp;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

import foundation.privacybydesign.irmaandroid.InvalidRequest;
import foundation.privacybydesign.irmaandroid.irmaandroid;

public class MainActivity extends AppCompatActivity {

    RequestQueue queue;
    int state=0;
    static final int STATE_INITIAL = 0;
    static final int STATE_STARTING = 1;
    static final int STATE_WAITING = 2;
    static final int STATE_FETCHING = 3;
    static final int STATE_DONE = 4;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        // Basic setup for network connectivity
        queue = Volley.newRequestQueue(this);
        // And initialize our state
        reset();
    }

    @Override
    protected void onStart() {
        super.onStart();
        Intent intent = getIntent();
        if (intent.getAction() == Intent.ACTION_VIEW) {
            // Handle the result of the irma session, this will be application specific!
            //
            // Here we just query the server for the disclosed attribute and display it
            // but you might want to do different things here, such as letting the server
            // return an access token.
            //
            // In a production app, this is also where you handle sessions that were
            // cancelled or gave an error. Here, that just results in the text ERROR or
            // CANCELLED being returned by the server and being displayed.
            final TextView output = (TextView) findViewById(R.id.textView);
            final Button inputButton = (Button) findViewById(R.id.button);
            output.setText("Fetching result...");
            inputButton.setText("Reset");
            state = STATE_FETCHING;

            Uri input = intent.getData();
            if (input != null && input.getQuery() != null) {
                try {
                    // Extract session token, and construct query string
                    String fetchAddr = "http://127.0.0.1:8080/fetch?" + URLEncoder.encode(input.getQuery(), "UTF-8");
                    // Do the http(s) request
                    StringRequest stringRequest = new StringRequest(Request.Method.GET, fetchAddr,
                            new Response.Listener<String>() {
                                @Override
                                public void onResponse(String response) {
                                    // And display the response from the server
                                    if (state == STATE_FETCHING) {
                                        output.setText("Result: " + response);
                                        state = STATE_DONE;
                                    }
                                }
                            }, new Response.ErrorListener() {
                        @Override
                        public void onErrorResponse(VolleyError error) {
                            output.setText("Error: " + error.getMessage());
                        }
                    });

                    stringRequest.setTag(this);
                    queue.add(stringRequest);
                } catch (UnsupportedEncodingException e) {
                    output.setText("Error: UnsupportedEncodingException");
                }
            } else {
                output.setText("Error: Intent URI action without URI!?");
            }
        }
    }

    private void reset() {
        // Reset the internal state and the display elements.
        final TextView output = (TextView) findViewById(R.id.textView);
        final Button input = (Button) findViewById(R.id.button);

        output.setText("Ready");
        input.setText("Start session");
        state = STATE_INITIAL;
    }

    public void sendMessage(View view) {
        // Handle the button
        final TextView output = (TextView) findViewById(R.id.textView);
        final Button input = (Button) findViewById(R.id.button);

        if (state == STATE_INITIAL) {
            output.setText("Starting irma session...");
            input.setText("Reset");
            state = STATE_STARTING;

            // We ask the server for a session.
            final Activity RequestingActivity = this;
            String startUrl = "http://127.0.0.1:8080/startSession";
            JsonObjectRequest objectRequest = new JsonObjectRequest(Request.Method.GET, startUrl, null,
                    new Response.Listener<JSONObject>() {
                        @Override
                        public void onResponse(JSONObject response) {
                            try {
                                if (state == STATE_STARTING && response.has("token") && response.has("sessionptr")) {
                                    // We get back a token known to the server (so it can give us
                                    // results later), and the session pointer (which the irma app
                                    // needs to start the actual irma transaction).

                                    // Construct an URI that is intercepted by the app. This demo uses a deep link on example.com, but you will want to choose something you control here.
                                    String returnURI = "http://example.com/retToApp/?" + URLEncoder.encode(response.getString("token"), "UTF-8");

                                    // Call the irma app
                                    irmaandroid.StartIRMA(response.getString("sessionptr"), returnURI, RequestingActivity);

                                    // And update the interface
                                    output.setText("Waiting....");
                                    state = STATE_WAITING;
                                }
                            } catch (InvalidRequest e) {
                                output.setText("Error: Invalid request");
                            } catch (JSONException e) {
                                output.setText("Error: Internal error (JSON)");
                            } catch (UnsupportedEncodingException e) {
                                output.setText("Error: Internal error (Encoding)");
                            }
                        }
                    }, new Response.ErrorListener() {
                @Override
                public void onErrorResponse(VolleyError error) {
                    output.setText("Error: " + error.getMessage());
                }
            });

            objectRequest.setTag(this);
            queue.add(objectRequest);
        } else {
            reset();
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        // Do some cleanup on the volley network queue
        queue.cancelAll(this);
    }
}