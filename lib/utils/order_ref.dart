String shortOrderRef(String id) {
  return id.length <= 8 ? id.toUpperCase() : id.substring(id.length - 8).toUpperCase();
}
