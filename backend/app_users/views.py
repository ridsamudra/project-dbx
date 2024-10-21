# app_users/views.py

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Users
from app_users_locations.models import UsersLocations
from app_locations.models import Locations
from .utils import is_admin_user, fetch_user_locations

@csrf_exempt
def login_view(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            id_user = data.get('id_user')
            password = data.get('password')

            try:
                user = Users.objects.get(id_user=id_user)
            except Users.DoesNotExist:
                return JsonResponse({'error': 'User tidak ditemukan!'}, status=404)

            if user.password == password:
                session_data = {
                    'id': user.id,
                    'id_user': user.id_user,
                    'admin': user.admin,
                }
                return JsonResponse({'message': 'Login berhasil!', 'session_data': session_data})
            else:
                return JsonResponse({'error': 'Password salah!'}, status=403)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
    
    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def logout_view(request):
    return JsonResponse({'message': 'Logout berhasil', 'session_data': {}})

@csrf_exempt
def list_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            session_data = data.get('session_data')

            if not session_data:
                return JsonResponse({'error': 'Missing session_data'}, status=400)

            if not is_admin_user(session_data):
                return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat melihat daftar user.'}, status=403)

            # Filter hanya user biasa (admin=0)
            users = Users.objects.filter(admin=0).values('id', 'id_user', 'nama_user', 'password')
            return JsonResponse(list(users), safe=False)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    
    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def add_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            session_data = data.get('session_data')
            user_data = data.get('user_data')

            if not session_data or not user_data:
                return JsonResponse({'error': 'Missing session_data or user_data'}, status=400)

            if not is_admin_user(session_data):
                return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat menambahkan user.'}, status=403)

            # Ensure only regular users can be added
            if user_data.get('admin', 0) != 0:
                return JsonResponse({'error': 'Hanya user biasa yang dapat ditambahkan.'}, status=400)

            new_user = Users(
                id_user=user_data['id_user'],
                nama_user=user_data['nama_user'],
                password=user_data.get('password', '1234'),  # Default password
                admin=0  # Always set as regular user
            )
            new_user.save()
            return JsonResponse({'message': 'User berhasil ditambahkan.', 'id': new_user.id}, status=201)
        except KeyError as e:
            return JsonResponse({'error': f'Missing required field: {str(e)}'}, status=400)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def update_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            session_data = data.get('session_data')
            user_data = data.get('user_data')
            user_id = data.get('user_id')

            if not session_data or not user_data or not user_id:
                return JsonResponse({'error': 'Missing session_data, user_data, or user_id'}, status=400)

            if not is_admin_user(session_data):
                return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat mengupdate user.'}, status=403)

            try:
                user = Users.objects.get(id=user_id)
                
                # Ensure only regular users can be updated
                if user.admin:
                    return JsonResponse({'error': 'Hanya data user biasa yang dapat diupdate.'}, status=400)

                user.id_user = user_data.get('id_user', user.id_user)
                user.nama_user = user_data.get('nama_user', user.nama_user)
                if 'password' in user_data:
                    user.password = user_data['password']
                
                user.save()
                return JsonResponse({'message': 'User berhasil diupdate.'}, status=200)
            except Users.DoesNotExist:
                return JsonResponse({'error': 'User tidak ditemukan.'}, status=404)
            
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def delete_user(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            session_data = data.get('session_data')
            user_id = data.get('user_id')

            if not session_data or not user_id:
                return JsonResponse({'error': 'Missing session_data or user_id'}, status=400)

            if not is_admin_user(session_data):
                return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat menghapus user.'}, status=403)

            try:
                user = Users.objects.get(id=user_id)
                user.delete()
                return JsonResponse({'message': 'User berhasil dihapus.'}, status=200)
            except Users.DoesNotExist:
                return JsonResponse({'error': 'User tidak ditemukan.'}, status=404)
            except Exception as e:
                return JsonResponse({'error': str(e)}, status=500)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def change_password(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            session_data = data.get('session_data')
            old_password = data.get('old_password')
            new_password = data.get('new_password')

            if not session_data or not old_password or not new_password:
                return JsonResponse({'error': 'Missing required data'}, status=400)

            user_id = session_data.get('id')
            if not user_id:
                return JsonResponse({'error': 'Invalid session data'}, status=400)

            try:
                user = Users.objects.get(id=user_id)
                if user.password != old_password:
                    return JsonResponse({'error': 'Password lama tidak sesuai'}, status=403)

                user.password = new_password
                user.save()
                return JsonResponse({'message': 'Password berhasil diubah'}, status=200)
            except Users.DoesNotExist:
                return JsonResponse({'error': 'User tidak ditemukan'}, status=404)

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)

    return JsonResponse({'error': 'Invalid method'}, status=405)

@csrf_exempt
def manage_user_locations(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        data = json.loads(request.body)
        session_data = data.get('session_data')
        operation = data.get('operation')
        user_id = data.get('user_id')
        location_id = data.get('location_id')

        if not all([session_data, operation, user_id, location_id]):
            return JsonResponse({'error': 'Missing required data'}, status=400)

        if not is_admin_user(session_data):
            return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat mengelola lokasi user.'}, status=403)

        target_user = Users.objects.get(id=user_id)
        if target_user.admin:
            return JsonResponse({'error': 'Tidak dapat mengelola lokasi untuk user admin'}, status=400)

        location = Locations.objects.get(id=location_id)

        if operation == 'add':
            UsersLocations.objects.get_or_create(id_user=target_user, id_lokasi=location)
            return JsonResponse({'message': 'Lokasi berhasil ditambahkan ke user'}, status=201)
        elif operation == 'remove':
            UsersLocations.objects.filter(id_user=target_user, id_lokasi=location).delete()
            return JsonResponse({'message': 'Lokasi berhasil dihapus dari user'}, status=200)
        else:
            return JsonResponse({'error': 'Invalid operation'}, status=400)

    except Users.DoesNotExist:
        return JsonResponse({'error': 'User tidak ditemukan'}, status=404)
    except Locations.DoesNotExist:
        return JsonResponse({'error': 'Lokasi tidak ditemukan'}, status=404)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def list_locations(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        data = json.loads(request.body)
        session_data = data.get('session_data')

        if not session_data:
            return JsonResponse({'error': 'Missing session_data'}, status=400)

        if not is_admin_user(session_data):
            return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat melihat daftar lokasi.'}, status=403)

        locations = Locations.objects.all().values('id', 'site')
        return JsonResponse(list(locations), safe=False)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def get_user_locations(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid method'}, status=405)

    try:
        data = json.loads(request.body)
        session_data = data.get('session_data')
        user_id = data.get('user_id')

        if not session_data or not user_id:
            return JsonResponse({'error': 'Missing required data'}, status=400)

        if not is_admin_user(session_data):
            return JsonResponse({'error': 'Akses ditolak. Hanya admin yang dapat melihat lokasi user.'}, status=403)

        try:
            user = Users.objects.get(id=user_id)
        except Users.DoesNotExist:
            return JsonResponse({'error': 'User tidak ditemukan'}, status=404)

        user_locations = UsersLocations.objects.filter(id_user=user).select_related('id_lokasi').values('id_lokasi__id', 'id_lokasi__site')
        locations = [{'id': loc['id_lokasi__id'], 'site': loc['id_lokasi__site']} for loc in user_locations]

        return JsonResponse({'locations': locations})
    except json.JSONDecodeError:
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)