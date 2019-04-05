module ODBCAdapter
  class QueryTimeoutError < ActiveRecord::StatementInvalid
  end
  class ConnectionFailedError < ActiveRecord::StatementInvalid
  end
end
