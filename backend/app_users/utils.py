# app_users/utils.py

import json
from app_users.models import Users
from app_locations.models import Locations
from app_users_locations.models import UsersLocations
from django.core.exceptions import ObjectDoesNotExist

def get_session_data_from_body(request):
    """
    Ambil session data dari request body.
    Mengembalikan session_data dalam bentuk dict atau error message jika gagal.
    """
    try:
        request_data = json.loads(request.body)
        session_data = request_data.get('session_data')
        if session_data is None:
            return {"error": "Session data tidak ditemukan di request body."}
        
        return session_data
    except json.JSONDecodeError:
        return {"error": "Session data tidak valid, tidak dapat di-decode."}

def is_admin_user(session_data):
    """
    Validasi apakah user adalah admin berdasarkan session_data.
    Mengembalikan True jika user adalah admin, False jika bukan admin.
    """
    try:
        # Cek 'admin' field di session_data
        is_admin = session_data.get('admin')
        if is_admin is None:
            raise ValueError("Session data tidak valid: 'admin' field tidak ditemukan.")
        return is_admin == 1
    except ValueError as ve:
        return {"error": str(ve)}
    except Exception as e:
        return {"error": f"Terjadi kesalahan: {str(e)}"}

def fetch_user_locations(session_data):
    """
    Function untuk nge-fetch lokasi berdasarkan status user (admin atau user biasa).
    Jika user admin, return semua lokasi.
    Jika user biasa, return lokasi yang diassign ke user tersebut.
    Mengembalikan error message jika tidak berhasil.
    """
    try:
        # Validasi apakah user admin
        is_admin_check = is_admin_user(session_data)
        if isinstance(is_admin_check, dict):  # Handle kalau is_admin_user return error
            return is_admin_check

        if is_admin_check:
            locations = Locations.objects.all()  # Semua lokasi di table tm_lokasi
            if not locations.exists():
                raise ObjectDoesNotExist("Tidak ada lokasi yang tersedia.")
        else:
            user_id = session_data.get('id')
            if not user_id:
                raise ValueError("Session data tidak valid: 'id' field tidak ditemukan.")
            
            # Ambil id lokasi yang terkait dengan user dari UsersLocations
            user_locations = UsersLocations.objects.filter(id_user=user_id).values_list('id_lokasi', flat=True)
            if not user_locations:
                raise ObjectDoesNotExist(f"Tidak ada lokasi yang diassign untuk user dengan id {user_id}.")

            # Ambil lokasi berdasarkan id yang didapat dari UsersLocations
            locations = Locations.objects.filter(id__in=user_locations)  # Ini yang benar, `id__in` untuk query Many-to-Many
            if not locations.exists():
                raise ObjectDoesNotExist("Tidak ada lokasi yang ditemukan untuk user tersebut.")

        return locations

    except ObjectDoesNotExist as e:
        return {"error": str(e)}
    except ValueError as ve:
        return {"error": str(ve)}
    except Exception as e:
        return {"error": f"Terjadi kesalahan saat fetch data lokasi: {str(e)}"}
