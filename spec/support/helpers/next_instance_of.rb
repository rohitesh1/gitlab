# frozen_string_literal: true

module NextInstanceOf
  def expect_next_instance_of(klass, *new_args, &blk)
    stub_new(expect(klass), nil, *new_args, &blk)
  end

  def expect_next_instances_of(klass, number, *new_args, &blk)
    stub_new(expect(klass), number, *new_args, &blk)
  end

  def allow_next_instance_of(klass, *new_args, &blk)
    stub_new(allow(klass), nil, *new_args, &blk)
  end

  def allow_next_instances_of(klass, number, *new_args, &blk)
    stub_new(allow(klass), number, *new_args, &blk)
  end

  private

  def stub_new(target, number, *new_args, &blk)
    receive_new = receive(:new)
    receive_new.exactly(number).times if number
    receive_new.with(*new_args) if new_args.any?

    target.to receive_new.and_wrap_original do |method, *original_args|
      method.call(*original_args).tap(&blk)
    end
  end
end
