import '../../core/error/result.dart';
import '../../data/local/bike_storage.dart';
import '../../domain/entities/bike_profile.dart';
import '../../domain/repositories/bike_repository.dart';

/// Concrete implementation of [BikeRepository] backed by [BikeStorage].
class BikeRepositoryImpl implements BikeRepository {
  const BikeRepositoryImpl(this._storage);
  final BikeStorage _storage;

  @override
  Future<Result<List<BikeProfile>>> getBikes() => _storage.loadAll();

  @override
  Future<Result<BikeProfile>> getBike(String slug) => _storage.load(slug);

  @override
  Future<Result<BikeProfile>> createBike(BikeProfile bike) async {
    // Check for duplicate slug
    final existing = await _storage.load(bike.slug);
    if (existing is Success) {
      return Failure(
          ValidationException("Bike '${bike.slug}' already exists"));
    }
    final saved = await _storage.save(bike);
    return saved.fold(
      onSuccess: (_) => Success(bike),
      onFailure: Failure.new,
    );
  }

  @override
  Future<Result<BikeProfile>> updateBike(String slug, BikeProfile bike) async {
    final saved = await _storage.save(bike.copyWith(slug: slug));
    return saved.fold(
      onSuccess: (_) => Success(bike),
      onFailure: Failure.new,
    );
  }

  @override
  Future<Result<void>> deleteBike(String slug) => _storage.delete(slug);
}
