class Loader:
    """Loads records from the warehouse."""

    def fetch(self, record_id: int) -> dict:
        """Fetch a single record by id."""
        return {'id': record_id}
