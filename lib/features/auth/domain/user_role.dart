enum UserRole {
  trainee('trainee', 'Trainee'),
  coach('coach', 'Coach'),
  masterAdmin('master_admin', 'Master Admin');

  const UserRole(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.firestoreValue == value,
      orElse: () => UserRole.trainee,
    );
  }
}
