package com.babariviere.sms;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.provider.Telephony;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class SmsDb implements MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {
    private PluginRegistry.Registrar registrar;
    private String TAG = "SMSDb";

    SmsDb(PluginRegistry.Registrar registrar) {
        this.registrar = registrar;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "insertMessage":
                boolean insertResult = insertMessage(methodCall.arguments);

                if (insertResult)
                    result.success(insertResult);
                else
                    result.error("Could not insert message", "", methodCall.arguments);

                break;
            case "insertMessages":
                JSONArray messagesArray = (JSONArray) methodCall.arguments;
                Log.d(TAG, methodCall.method + "called with: " + messagesArray.length() + " messages");
                Map<Object, Boolean> results = insertMessages(messagesArray);
                assert (results != null);
                result.success(results);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private ContentValues convert(Object argument) {
        JSONObject messageMap = (JSONObject) argument;
        ContentValues cv = new ContentValues();
        try {
            String address = (String) messageMap.get("address");

            String body = messageMap.getString("body");
            long date = messageMap.get("date") == null ? Long.valueOf("") :
                    Long.valueOf(messageMap.get("date").toString());
            long dateSent = (messageMap.get("dateSent") == null) ? dateSent = Long.valueOf("") :
                    Long.valueOf(messageMap.get("dateSent").toString());
            int read = messageMap.getInt("read");
            int kind = messageMap.getInt("kind");

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                cv.put(Telephony.Sms.ADDRESS, address);
                cv.put(Telephony.Sms.BODY, body);
                cv.put(Telephony.Sms.DATE, date);
                cv.put(Telephony.Sms.DATE_SENT, dateSent);
                cv.put(Telephony.Sms.READ, read);
                cv.put("kind", kind);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }

        return cv;
    }

    boolean verifyInsertionSuccess() {
        return true;
    }


    @SuppressLint("NewApi")
    private Uri getBox(Integer kind) {
        switch (kind) {
            case 0:
                return Telephony.Sms.Sent.CONTENT_URI;
            case 1:
                return Telephony.Sms.Inbox.CONTENT_URI;
            case 2:
                return Telephony.Sms.Draft.CONTENT_URI;
            case 3:
            case 4:
            case 5:
                return Telephony.Sms.Outbox.CONTENT_URI;
            default:
                return Telephony.Sms.Inbox.CONTENT_URI;
        }

    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private boolean insertMessage(Object arguments) {
        ContentValues cv = convert(arguments);
        Log.d(TAG, "insertMessage: " + cv);
        Uri box = getBox(cv.getAsInteger("kind"));
        cv.remove("kind");
        Uri u = registrar.context().getContentResolver().insert(box, cv);
        Cursor c = registrar.context().getContentResolver().query(u, null, null, null, null);
        if (c != null) {

            //more to the first row
            c.moveToFirst();

            //iterate over rows
            for (int i = 0; i < c.getCount(); i++) {
                StringBuilder stringBuilder2 = new StringBuilder();
                //iterate over the columns
                for (int j = 0; j < c.getColumnNames().length; j++) {
                    //append the column value to the string builder and delimit by a pipe symbol
                    stringBuilder2.append(c.getColumnName(j)).append(": ").append(c.getString(j)).append(" | ");
                }
                Log.d(TAG, "insertMessage: Values:" + stringBuilder2.toString());

                //add a new line carriage return
                //move to the next row
                c.moveToNext();
            }
            //close the cursor
            c.close();
            Log.d(TAG, "insertMessage: Uri u: " + (u != null ? u.toString() : ""));
        }
        if (u != null) return true;
        else {
            Log.d(TAG, "insertMessage: " + cv + "\n _________Failed to insert!!!______");
            return false;
        }
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private Map<Object, Boolean> insertMessages(JSONArray messages) {
        HashMap results = new HashMap();
        Log.d(TAG, "_____________________________________");
        for (int i = 0; i < messages.length(); i++) {
            Log.d(TAG, "insertMessages: iteration " + (i + 1) + " of " + messages.length());
            try {
                results.put(messages.get(i), insertMessage(messages.get(i)));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        Log.d(TAG, "_____________________________________");
        return results;
    }

    @Override
    public boolean onRequestPermissionsResult(int i, String[] strings, int[] ints) {
        return false;
    }
}
