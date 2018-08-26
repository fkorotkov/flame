# frozen_string_literal: true

module Flame
	class Router
		class RoutesRefine
			## Module for mounting in RoutesRefine
			module Mounting
				private

				using GorillaPatch::Transform
				using GorillaPatch::DeepMerge

				## Mount controller inside other (parent) controller
				## @param controller [Flame::Controller] class of mounting controller
				## @param path [String, nil] root path for mounting controller
				## @yield Block of code for routes refine
				def mount(controller_name, path = nil, &block)
					routes_refine = self.class.new(
						@namespace_name, controller_name, path, &block
					)

					@endpoint.deep_merge! routes_refine.routes

					@reverse_routes.merge!(
						routes_refine.reverse_routes.transform_values do |hash|
							hash.transform_values { |action_path| @path + action_path }
						end
					)
				end

				using GorillaPatch::Namespace

				def mount_nested_controllers
					return if (
						@controller.demodulize != 'IndexController' ||
						@namespace_name.empty?
					)

					namespace = Object.const_get(@namespace_name)

					namespace.constants.each do |controller_name|
						mount_nested_controller namespace.const_get(controller_name)
					end
				end

				def mount_nested_controller(nested_controller)
					return if !nested_controller.instance_of?(Module) && (
						nested_controller.actions.empty? ||
						@reverse_routes.key?(nested_controller.to_s)
					)

					mount nested_controller
				end
			end
		end
	end
end
