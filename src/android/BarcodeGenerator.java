package com.attendee.barcodegenerator;

import android.graphics.Bitmap;
import android.util.Base64;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.ByteArrayOutputStream;

/**
 * Created by Olipsist on 3/29/16 AD.
 */
public class BarcodeGenerator extends CordovaPlugin {

    public final static int WHITE = 0xFFFFFFFF;
    public final static int BLACK = 0xFF000000;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (action.equals("barcodeGenerator")){
            String data = args.getString(0);
            try {
                this.generateBarcode(data, callbackContext);
            } catch (WriterException e) {
                e.printStackTrace();
            }
            return true;
        }

        return false;
    }


    private void generateBarcode(String data ,CallbackContext callbackContext) throws WriterException {
        BitMatrix result = null;
        try{
            result = new MultiFormatWriter().encode(data, BarcodeFormat.CODE_128,300,300,null);
        } catch (IllegalArgumentException e){

        }

        int w = result.getWidth();
        int h = result.getHeight();
        int[] pixels = new int[w * h];
        for (int y = 0; y < h; y++) {
            int offset = y * w;
            for (int x = 0; x < w; x++) {
                pixels[offset + x] = result.get(x, y) ? BLACK : WHITE;
            }
        }
        Bitmap bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        bitmap.setPixels(pixels, 0, 300, 0, 0, w, h);

        String base64Image =  bitmapToBase64(bitmap);

        if (data!=null && data.length() > 0 && base64Image.length()>0){
            callbackContext.success(base64Image);
        }else {
            callbackContext.error("ERROR CANNOT GENERATION");
        }
    }


    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream .toByteArray();
        return Base64.encodeToString(byteArray, Base64.DEFAULT);
    }

}
