import 'package:dio/dio.dart';
import 'package:testflutter/core/error/exceptions.dart';
import 'package:testflutter/data/models/todo_model.dart';

abstract class PingRemoteDataSource {
  Future<TodoModel> fetchSampleTodo();
}

class PingRemoteDataSourceImpl implements PingRemoteDataSource {
  final Dio dio;

  PingRemoteDataSourceImpl({required this.dio});

  @override
  Future<TodoModel> fetchSampleTodo() async {
    try {
      final response = await dio.get('https://jsonplaceholder.typicode.com/todos/1');
      return TodoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException('REST API call failed: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected REST API error: $e');
    }
  }
}
