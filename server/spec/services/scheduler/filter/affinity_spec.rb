require_relative '../../../spec_helper'

describe Scheduler::Filter::Affinity do

  let(:nodes) do
    nodes = []
    nodes << HostNode.create!(node_id: 'node1', name: 'node-1')
    nodes << HostNode.create!(node_id: 'node2', name: 'node-2')
    nodes << HostNode.create!(node_id: 'node3', name: 'node-3')
    nodes
  end

  describe '#for_service' do
    it 'returns all nodes if service does not have any affinities defined' do
      service = double(:service, affinity: [])
      filtered = subject.for_service(service, 'redis-1', nodes)
      expect(filtered).to eq(nodes)
    end

    context 'node' do
      it 'returns node-1 if affinity: node==node-1' do
        service = double(:service, affinity: ['node==node-1'])
        filtered = subject.for_service(service, 'redis-1', nodes)
        expect(filtered.size).to eq(1)
        expect(filtered).to eq([nodes[0]])
      end

      it 'returns node-1 if affinity: node!=node-2,node!=node-3' do
        service = double(:service, affinity: ['node!=node-2', 'node!=node-3'])
        filtered = subject.for_service(service, 'redis-1', nodes)
        expect(filtered.size).to eq(1)
        expect(filtered).to eq([nodes[0]])
      end

      it 'does not return node-3 if affinity: node!=node-3' do
        service = double(:service, affinity: ['node!=node-3'])
        filtered = subject.for_service(service, 'redis-1', nodes)
        expect(filtered.size).to eq(2)
        expect(filtered).to eq(nodes - [nodes[2]])
      end
    end

    context 'container' do
      let(:service) { GridService.create!(name: 'redis', image_name: 'redis:2.8')}

      before(:each) do
        service.containers.create!(name: 'redis-1', host_node: nodes[0])
        service.containers.create!(name: 'redis-2', host_node: nodes[1])
      end

      it 'returns node-1 if affinity: container==redis-1' do
        service = double(:service, affinity: ['container==redis-1'])
        filtered = subject.for_service(service, 'app-1', nodes)
        expect(filtered.size).to eq(1)
        expect(filtered).to eq([nodes[0]])
      end

      it 'returns node-2 if affinity: container==redis-%i and current container name is app-2' do
        service = double(:service, affinity: ['container==redis-%i'])
        filtered = subject.for_service(service, 'app-2', nodes)
        expect(filtered.size).to eq(1)
        expect(filtered).to eq([nodes[1]])
      end

      it 'does not return node-2 if affinity: container!=redis-2' do
        service = double(:service, affinity: ['container!=redis-2'])
        filtered = subject.for_service(service, 'app-1', nodes)
        expect(filtered.size).to eq(2)
        expect(filtered).to eq(nodes - [nodes[1]])
      end
    end
  end
end