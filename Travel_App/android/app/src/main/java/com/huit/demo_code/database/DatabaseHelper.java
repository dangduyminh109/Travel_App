package vn.com.huit.travelapp.database;

import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class DatabaseHelper extends SQLiteOpenHelper {

    private static final String DB_NAME = "travel_app.db";
    private static final int DB_VERSION = 1;
    private static final String TABLE_USERS = "users";
    private static final String COL_UID = "uid";
    private static final String COL_EMAIL = "email";
    private static final String COL_DISPLAY_NAME = "displayName";
    private static final String COL_ROLE = "role";

    public DatabaseHelper(Context context) {
        super(context, DB_NAME, null, DB_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        String sql = "CREATE TABLE " + TABLE_USERS + " ("
                + COL_UID + " TEXT PRIMARY KEY, "
                + COL_EMAIL + " TEXT NOT NULL, "
                + COL_DISPLAY_NAME + " TEXT, "
                + COL_ROLE + " TEXT DEFAULT 'user'"
                + ")";
        db.execSQL(sql);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_USERS);
        onCreate(db);
    }

    public void saveUser(String uid, String email, String displayName, String role) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        values.put(COL_UID, uid);
        values.put(COL_EMAIL, email);
        values.put(COL_DISPLAY_NAME, displayName);
        values.put(COL_ROLE, role);
        db.insertWithOnConflict(TABLE_USERS, null, values, SQLiteDatabase.CONFLICT_REPLACE);
        db.close();
    }

    public Cursor getUser(String uid) {
        SQLiteDatabase db = this.getReadableDatabase();
        return db.query(TABLE_USERS, null, COL_UID + "=?", new String[] { uid }, null, null, null);
    }

    public void deleteUser(String uid) {
        SQLiteDatabase db = this.getWritableDatabase();
        db.delete(TABLE_USERS, COL_UID + "=?", new String[] { uid });
        db.close();
    }
}
