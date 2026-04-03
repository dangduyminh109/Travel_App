package vn.com.huit.travelapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import java.util.ArrayList;
import java.util.List;

public class FavoritesHelper extends SQLiteOpenHelper {

    private static final String DB_NAME = "favorites.db";
    private static final int DB_VERSION = 1;
    private static final String TABLE_FAVORITES = "favorites";
    private static final String COL_DESTINATION_ID = "destinationId";
    private static final String COL_USER_ID = "userId";
    private static final String COL_SYNC_STATUS = "syncStatus";

    public FavoritesHelper(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        String sql = "CREATE TABLE " + TABLE_FAVORITES + " ("
                + COL_DESTINATION_ID + " TEXT, "
                + COL_USER_ID + " TEXT, "
                + COL_SYNC_STATUS + " INTEGER DEFAULT 0, "
                + "PRIMARY KEY (" + COL_DESTINATION_ID + ", " + COL_USER_ID + ")"
                + ")";
        db.execSQL(sql);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_FAVORITES);
        onCreate(db);
    }

    public void addFavorite(String destinationId, String userId) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put(COL_DESTINATION_ID, destinationId);
        values.put(COL_USER_ID, userId);
        values.put(COL_SYNC_STATUS, 0);
        db.insertWithOnConflict(TABLE_FAVORITES, null, values, SQLiteDatabase.CONFLICT_REPLACE);
        db.close();
    }

    public void removeFavorite(String destinationId, String userId) {
        SQLiteDatabase db = this.getWritableDatabase();
        db.delete(TABLE_FAVORITES,
                COL_DESTINATION_ID + "=? AND " + COL_USER_ID + "=?",
                new String[] { destinationId, userId });
        db.close();
    }

    public boolean isFavorite(String destinationId, String userId) {
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query(TABLE_FAVORITES, null,
                COL_DESTINATION_ID + "=? AND " + COL_USER_ID + "=?",
                new String[] { destinationId, userId }, null, null, null);
        boolean exists = cursor.getCount() > 0;
        cursor.close();
        return exists;
    }

    public void updateSyncStatus(String destinationId, String userId, int status) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put(COL_SYNC_STATUS, status);
        db.update(TABLE_FAVORITES, values,
                COL_DESTINATION_ID + "=? AND " + COL_USER_ID + "=?",
                new String[] { destinationId, userId });
        db.close();
    }

    public List<String> getUnsyncedFavorites(String userId) {
        List<String> list = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query(TABLE_FAVORITES,
                new String[] { COL_DESTINATION_ID },
                COL_USER_ID + "=? AND " + COL_SYNC_STATUS + "=0",
                new String[] { userId }, null, null, null);
        if (cursor.moveToFirst()) {
            do {
                list.add(cursor.getString(0));
            } while (cursor.moveToNext());
        }
        cursor.close();
        return list;
    }

    public List<String> getAllFavorites(String userId) {
        List<String> list = new ArrayList<>();
        SQLiteDatabase db = this.getReadableDatabase();
        Cursor cursor = db.query(TABLE_FAVORITES,
                new String[] { COL_DESTINATION_ID },
                COL_USER_ID + "=?",
                new String[] { userId }, null, null, null);
        if (cursor.moveToFirst()) {
            do {
                list.add(cursor.getString(0));
            } while (cursor.moveToNext());
        }
        cursor.close();
        return list;
    }
}
