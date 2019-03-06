require "pattern_query_helper/version"
require "pattern_query_helper/pagination"
require "pattern_query_helper/filtering"
require "pattern_query_helper/associations"
require "pattern_query_helper/sorting"
require "pattern_query_helper/sql"

module PatternQueryHelper

  def self.run_sql_query(model, query, query_params, query_helpers, single_record=false)
    PatternQueryHelper::Sql.parse_result_columns(query)
    if single_record
      single_record_sql_query(model, query, query_params, query_helpers)
    elsif query_helpers[:per_page] || query_helpers[:page]
      paginated_sql_query(model, query, query_params, query_helpers)
    else
      sql_query(model, query, query_params, query_helpers)
    end
  end

  def self.run_active_record_query(active_record_call, query_helpers, single_record=false)
    run_sql_query(active_record_call.model, active_record_call.to_sql, {}, query_helpers, single_record)
  end

  private

  def self.paginated_sql_query(model, query, query_params, query_helpers)
    query_helpers = parse_helpers(query_helpers)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      page: query_helpers[:pagination][:page],
      per_page: query_helpers[:pagination][:per_page],
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.sql_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])
    count = PatternQueryHelper::Sql.sql_query_count(query_config)
    pagination = PatternQueryHelper::Pagination.create_pagination_payload(count, query_helpers[:pagination])

    {
      pagination: pagination,
      data: data
    }
  end

  def self.sql_query(model, query, query_params, query_helpers)
    query_helpers = parse_helpers(query_helpers)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.sql_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])

    {
      data: data
    }
  end

  def self.single_record_sql_query(model, query, query_params, query_helpers)
    query_helpers = parse_helpers(query_helpers)

    query_config = {
      model: model,
      query: query,
      query_params: query_params,
      filter_string: query_helpers[:filters][:filter_string],
      filter_params: query_helpers[:filters][:filter_params],
      sort_string: query_helpers[:sorting],
    }

    data = PatternQueryHelper::Sql.single_record_query(query_config)
    data = PatternQueryHelper::Associations.load_associations(data, query_helpers[:associations])

    {
      data: data
    }
  end

  def self.parse_helpers(params, valid_columns = [])
    filtering = PatternQueryHelper::Filtering.create_filters(params[:filter])
    sorting = PatternQueryHelper::Sorting.parse_sorting_params(params[:sort])
    associations = PatternQueryHelper::Associations.process_association_params(params[:include])
    pagination = PatternQueryHelper::Pagination.parse_pagination_params(params[:page], params[:per_page])

    {
      filters: filtering,
      sorting: sorting,
      associations: associations,
      pagination: pagination
    }
  end

  class << self
    attr_accessor :active_record_adapter
  end
end
