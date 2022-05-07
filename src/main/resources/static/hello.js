function Hello($scope, $http) {
  $http.get('/api/hello-world').
  success(function(data) {
    $scope.greeting = data;
  });
}
