module YAML
	class << self
		alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
		alias_method :original_dump, :dump
		alias_method :original_load_file, :load_file
	end

	def self.LOG(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Info] " + "#{info}"
	end

	def self.LOG_ERROR(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Error] " + "#{info}"
	end

	def self.LOG_WARN(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Warning] " + "#{info}"
	end

	def self.LOG_TIP(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Tip] " + "#{info}"
	end

	# Keep `short-id` as string before YAML parsing so leading zeros are preserved.
	# This is required for REALITY short-id values like `00000000`.
	def self.load_file(filename, *args, **kwargs)
		yaml_content = File.read(filename)
		processed_content = fix_short_id_quotes(yaml_content)

		if kwargs.empty?
			load(processed_content, *args)
		else
			load(processed_content, *args, **kwargs)
		end
	end

	def self.dump(obj, io = nil, **options)
		begin
		if io.nil?
			yaml_content = original_dump(obj, **options)
			fix_short_id_quotes(yaml_content)
		elsif io.respond_to?(:write)
			require 'stringio'
			temp_io = StringIO.new
			original_dump(obj, temp_io, **options)
			yaml_content = temp_io.string
			processed_content = fix_short_id_quotes(yaml_content)
			io.write(processed_content)
			io
		else
			yaml_content = original_dump(obj, io, **options)
			fix_short_id_quotes(yaml_content)
		end
		rescue => e
			LOG_ERROR("Write file failed:【%s】" % [e.message])
			nil
		end
	end

	private

	SHORT_ID_REGEX = /^(\s*)short-id:\s*(.*)$/
	LIST_ITEM_REGEX = /^(\s*)-\s*(.*)$/
	KEY_REGEX = /^(\s*)([a-zA-Z0-9_-]+):\s*(.*)$/
	QUOTED_VALUE_REGEX = /^(["'].*["']|null)$/

	# Inline map support, e.g. reality-opts: { ..., short-id: 00000000 }
	INLINE_SHORT_ID_REGEX = /(short-id:\s*)(?!["'\[]|null)([^\s,"'{}\[\]\n\r]+)(?=\s*(?:[,}\]\n\r]|$))/m.freeze

	def self.fix_short_id_quotes(yaml_content)
		return yaml_content unless yaml_content.include?('short-id:')

		begin
			# First, normalize inline-map style unquoted short-id.
			processed = yaml_content.gsub(INLINE_SHORT_ID_REGEX) do
				"#{$1}\"#{$2}\""
			end

			lines = processed.lines
			short_id_indices = lines.each_index.select { |i| lines[i] =~ SHORT_ID_REGEX }
			short_id_indices.each do |short_id_index|
				line = lines[short_id_index]
				if line =~ SHORT_ID_REGEX
					indent = $1
					value = $2.strip
					if value.empty?
						(short_id_index + 1...lines.size).each do |i|
							line = lines[i]
							next if line.strip.empty?
							if line[/^\s*/].length <= indent.length
								break
							end
							if line =~ LIST_ITEM_REGEX
								indent = $1
								value = $2.strip
								if value =~ KEY_REGEX
									break
								end
								if value !~ QUOTED_VALUE_REGEX
									lines[i] = "#{indent}- \"#{value}\"\n"
								end
							elsif line =~ KEY_REGEX
								break
							end
						end
					else
						if value !~ QUOTED_VALUE_REGEX
							lines[short_id_index] = "#{indent}short-id: \"#{value}\"\n"
						end
					end
				end
			end
			lines.join
		rescue => e
			LOG_ERROR("Fix short-id values type failed:【%s】" % [e.message])
			yaml_content
		end
	end

	def self.overwrite(base, override)
		return override if base.nil?
		return base if override.nil?

		current_key = nil
		current_operation = nil

		begin
			case override
			when Hash
				result = base.is_a?(Hash) ? base.dup : {}

				override.each do |key, value|
					current_key = key
					processed_key, operation = parse_key(key)
					current_operation = operation

					applied = apply_operation(result[processed_key], value, operation)
					if applied.equal?(DELETED_SENTINEL)
						result.delete(processed_key)
					else
						result[processed_key] = applied
					end
				end

				result
			else
				override
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【key: %s, operation: %s, error: %s】" % [current_key, current_operation, e.message])
			base
		end
	end

	private

	def self.parse_key(key)
		key_str = key.to_s

		# +<key>
		if key_str.start_with?('+<') && key_str.include?('>')
			close_idx = key_str.index('>')
			inner_key = key_str[2...close_idx]
			return inner_key, :prepend_array
		end

		# <key>suffix
		if key_str.start_with?('<') && key_str.include?('>')
			close_idx = key_str.index('>')
			inner_key = key_str[1...close_idx]
			suffix = key_str[(close_idx + 1)..-1]
			return inner_key, determine_operation(suffix)
		end

		# 前缀 +key
		if key_str.start_with?('+')
			return key_str[1..-1], :prepend_array
		end

		# 尾部（支持 +, !, *, -）
		if key_str =~ /^(.*?)([+!*\-])$/
			return Regexp.last_match(1), determine_operation(Regexp.last_match(2))
		end

		[key_str, :merge]
	end

	def self.determine_operation(suffix)
		case suffix
		when '+'
			:append_array
		when '-'
			:delete
		when '!'
			:force_overwrite
		when '*'
			:batch_update
		else
			:merge
		end
	end

	def self.match_value(target, condition)
		return false if target.nil? || condition.nil?

		begin
			if condition.is_a?(String) && condition.start_with?('/') && condition.end_with?('/')
				pattern = condition[1...-1]
				regexp = Regexp.new(pattern)
				if target.is_a?(Array)
					target.any? { |item| item.to_s =~ regexp }
				else
					target.to_s =~ regexp
				end
			elsif condition.is_a?(Array) && target.is_a?(Array)
				condition.all? { |c| target.include?(c) }
			else
				target == condition
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【(match value) => target: %s, condition: %s, error: %s】" % [target, condition, e.message])
			false
		end
	end

	def self.deep_dup(obj)
		case obj
		when Array
			obj.map { |x| deep_dup(x) }
		when Hash
			obj.transform_values { |v| deep_dup(v) }
		else
			obj.dup rescue obj
		end
	end

	def self.merge_hash(base, value, prepend: false)
		if prepend
			result = {}

			value.each do |k, v|
				if base.key?(k)
					result[k] = apply_operation(base[k], v, :merge)
				else
					result[k] = deep_dup(v)
				end
			end

			base.each do |k, v|
				result[k] = deep_dup(v) unless result.key?(k)
			end

			result
		else
			result = deep_dup(base)

			value.each do |k, v|
				if result.key?(k)
					result[k] = apply_operation(result[k], v, :merge)
				else
					result[k] = deep_dup(v)
				end
			end

			result
		end
	end

	def self.delete_from_hash(base, value)
		result = deep_dup(base)

		case value
		when Array
			value.each { |k| result.delete(k) }
		when Hash
			value.each do |k, v|
				if v.nil? || v == true
					result.delete(k)
				elsif result[k].is_a?(Hash) && v.is_a?(Hash)
					nested = apply_operation(result[k], v, :delete)
					if nested.equal?(DELETED_SENTINEL)
						result.delete(k)
					else
						result[k] = nested
					end
				else
					result.delete(k)
				end
			end
		else
			result.delete(value)
		end

		result
	end

	DELETED_SENTINEL = Object.new.freeze

	def self.apply_operation(base, value, operation)
		case operation
		when :delete
			if base.is_a?(Array) && value.is_a?(Array)
				base - value
			elsif base.is_a?(Array) && !value.nil?
				base - [value]
			elsif base.is_a?(Hash)
				delete_from_hash(base, value)
			else
				DELETED_SENTINEL
			end
		when :force_overwrite
			deep_dup(value)
		when :prepend_array
			if base.is_a?(Array) && value.is_a?(Array)
				(deep_dup(value) + base).uniq
			elsif base.is_a?(Hash) && value.is_a?(Hash)
				merge_hash(base, value, prepend: true)
			else
				deep_dup(value)
			end
		when :append_array
			if base.is_a?(Array) && value.is_a?(Array)
				base_dup = base.dup
				deep_dup(value).each { |v| base_dup.delete(v) }
				base_dup + deep_dup(value)
			elsif base.is_a?(Hash) && value.is_a?(Hash)
				merge_hash(base, value, prepend: false)
			else
				deep_dup(value)
			end
		when :batch_update
			batch_update_items(base, value)
		when :merge
			if base.is_a?(Hash) && value.is_a?(Hash)
				overwrite(base, value)
			elsif value.nil?
				base
			else
				deep_dup(value)
			end
		else
			deep_dup(value)
		end
	end

	def self.apply_set_fields(item, set_values)
		keys_to_delete = []

		set_values.each do |k, v|
			processed_key, operation = parse_key(k)
			result = apply_operation(item[processed_key], v, operation)
			if result.equal?(DELETED_SENTINEL)
				keys_to_delete << processed_key
			else
				item[processed_key] = result
			end
		end

		keys_to_delete.each { |k| item.delete(k) }
	end

	def self.match_item(item, where_conditions, key = nil)
		where_conditions.all? do |k, v|
			if k == 'key' && !key.nil?
				match_value(key, v)
			elsif item.is_a?(Hash)
				match_value(item[k] || item[k.to_s], v)
			elsif item.is_a?(String) && k == 'value'
				match_value(item, v)
			else
				false
			end
		end
	end

	def self.batch_update_items(collection, update_spec)
		return collection unless update_spec.is_a?(Hash)

		begin
			where_conditions = update_spec['where'] || {}
			set_values = update_spec['set'] || {}

			if collection.is_a?(Array)
				result = collection.dup
				delete_indices = []

				result.each_with_index do |item, index|
					match = match_item(item, where_conditions)

					if match
						if item.is_a?(Hash)
							apply_set_fields(item, set_values)
						elsif item.is_a?(String) && set_values.key?('value')
							new_value = set_values['value']
							if new_value.nil?
								delete_indices << index
							else
								result[index] = deep_dup(new_value)
							end
						end
					end
				end

				delete_indices.reverse_each { |i| result.delete_at(i) }
				result
			elsif collection.is_a?(Hash)
				if where_conditions.any? { |k, _| k != 'key' } &&
					match_item(collection, where_conditions)
					result = collection.dup
					apply_set_fields(result, set_values)
					result
				else
					result = collection.dup
					keys_to_delete = []

					result.each do |key, value|
						next unless value.is_a?(Hash)
						match = match_item(value, where_conditions, key)

						if match
							if set_values.key?('key-') || (set_values.key?('key') && set_values['key'].nil?)
								keys_to_delete << key
							else
								apply_set_fields(value, set_values)
							end
						end
					end

					keys_to_delete.each { |k| result.delete(k) }
					result
				end
			elsif collection.nil?
				nil
			else
				collection
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【(batch update) => update_spec: %s, error: %s】" % [update_spec, e.message])
			collection
		end
	end
end