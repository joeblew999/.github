/**
 * NATS Container Orchestrator Worker
 * Manages NATS container instances on Cloudflare's container platform
 */

// Container class definition
export class NATSContainer extends Container {
  defaultPort = 4222; // NATS client port (template: ${nats_port})
  sleepAfter = '5m'; // Auto-sleep timeout (template: ${sleep_timeout})
  maxInstances = 5; // Maximum concurrent instances (template: ${max_instances})
}

// Main worker handler
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const pathname = url.pathname;

    try {
      // Route requests based on path
      if (pathname.startsWith('/nats/')) {
        return await handleNATSRequest(request, env, pathname);
      } else if (pathname.startsWith('/api/')) {
        return await handleAPIRequest(request, env, pathname);
      } else if (pathname.startsWith('/health')) {
        return await handleHealthCheck(request, env);
      } else {
        return new Response('NATS Container Orchestrator', {
          headers: { 'Content-Type': 'text/plain' }
        });
      }
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  },
};

/**
 * Handle NATS-specific requests
 */
async function handleNATSRequest(request, env, pathname) {
  const segments = pathname.split('/').filter(Boolean);
  
  if (segments.length < 2) {
    return new Response('Invalid NATS path', { status: 400 });
  }

  const sessionId = segments[1] || 'default';
  const action = segments[2] || 'connect';

  // Get or create NATS container instance
  const containerInstance = getContainer(env.NATS_CONTAINER, sessionId);

  switch (action) {
    case 'connect':
      // Forward connection to NATS container
      return await containerInstance.fetch(request);
      
    case 'info':
      // Get NATS server info
      return await getNATSInfo(containerInstance);
      
    case 'stats':
      // Get NATS server statistics
      return await getNATSStats(containerInstance);
      
    default:
      return await containerInstance.fetch(request);
  }
}

/**
 * Handle API requests for container management
 */
async function handleAPIRequest(request, env, pathname) {
  const segments = pathname.split('/').filter(Boolean);
  
  if (segments[1] === 'containers') {
    switch (request.method) {
      case 'GET':
        return await listContainers(env);
      case 'POST':
        return await createContainer(request, env);
      case 'DELETE':
        return await deleteContainer(request, env);
      default:
        return new Response('Method not allowed', { status: 405 });
    }
  }
  
  if (segments[1] === 'cluster') {
    return await handleClusterAPI(request, env, segments.slice(2));
  }

  return new Response('API endpoint not found', { status: 404 });
}

/**
 * Health check endpoint
 */
async function handleHealthCheck(request, env) {
  try {
    // Check if we can access KV and other bindings
    const kvTest = await env.NATS_CLUSTER_KV.get('health-check');
    
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        kv: 'available',
        r2: env.NATS_PERSISTENCE ? 'available' : 'not_configured',
        containers: 'available'
      }
    };

    return new Response(JSON.stringify(health), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Get NATS server information
 */
async function getNATSInfo(containerInstance) {
  try {
    // Create request to NATS HTTP monitoring endpoint
    const infoRequest = new Request('http://localhost:8222/varz', {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    });
    
    const response = await containerInstance.fetch(infoRequest);
    const info = await response.json();
    
    return new Response(JSON.stringify({
      server_info: info,
      container_id: containerInstance.id,
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to get NATS info',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Get NATS server statistics
 */
async function getNATSStats(containerInstance) {
  try {
    const statsRequest = new Request('http://localhost:8222/connz', {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    });
    
    const response = await containerInstance.fetch(statsRequest);
    const stats = await response.json();
    
    return new Response(JSON.stringify({
      connection_stats: stats,
      container_id: containerInstance.id,
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to get NATS stats',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * List active containers
 */
async function listContainers(env) {
  try {
    // Get container list from KV storage
    const containerList = await env.NATS_CLUSTER_KV.get('active-containers', 'json') || [];
    
    return new Response(JSON.stringify({
      containers: containerList,
      count: containerList.length,
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to list containers',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Create new container instance
 */
async function createContainer(request, env) {
  try {
    const body = await request.json();
    const sessionId = body.sessionId || `nats-${Date.now()}`;
    
    // Create container instance
    const containerInstance = getContainer(env.NATS_CONTAINER, sessionId);
    
    // Store container info in KV
    const containerInfo = {
      id: sessionId,
      created: new Date().toISOString(),
      config: body.config || {}
    };
    
    const containerList = await env.NATS_CLUSTER_KV.get('active-containers', 'json') || [];
    containerList.push(containerInfo);
    await env.NATS_CLUSTER_KV.put('active-containers', JSON.stringify(containerList));
    
    return new Response(JSON.stringify({
      success: true,
      container: containerInfo
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to create container',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Delete container instance
 */
async function deleteContainer(request, env) {
  try {
    const body = await request.json();
    const sessionId = body.sessionId;
    
    if (!sessionId) {
      return new Response('Session ID required', { status: 400 });
    }
    
    // Remove from active containers list
    const containerList = await env.NATS_CLUSTER_KV.get('active-containers', 'json') || [];
    const filteredList = containerList.filter(c => c.id !== sessionId);
    await env.NATS_CLUSTER_KV.put('active-containers', JSON.stringify(filteredList));
    
    return new Response(JSON.stringify({
      success: true,
      sessionId: sessionId
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to delete container',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Handle cluster management API
 */
async function handleClusterAPI(request, env, segments) {
  const action = segments[0];
  
  switch (action) {
    case 'join':
      return await handleClusterJoin(request, env);
    case 'leave':
      return await handleClusterLeave(request, env);
    case 'status':
      return await handleClusterStatus(request, env);
    default:
      return new Response('Unknown cluster action', { status: 400 });
  }
}

/**
 * Handle cluster join
 */
async function handleClusterJoin(request, env) {
  try {
    const body = await request.json();
    const nodeInfo = {
      id: body.nodeId,
      url: body.nodeUrl,
      joined: new Date().toISOString()
    };
    
    const clusterNodes = await env.NATS_CLUSTER_KV.get('cluster-nodes', 'json') || [];
    clusterNodes.push(nodeInfo);
    await env.NATS_CLUSTER_KV.put('cluster-nodes', JSON.stringify(clusterNodes));
    
    return new Response(JSON.stringify({
      success: true,
      node: nodeInfo,
      cluster_size: clusterNodes.length
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to join cluster',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Handle cluster leave
 */
async function handleClusterLeave(request, env) {
  try {
    const body = await request.json();
    const nodeId = body.nodeId;
    
    const clusterNodes = await env.NATS_CLUSTER_KV.get('cluster-nodes', 'json') || [];
    const filteredNodes = clusterNodes.filter(n => n.id !== nodeId);
    await env.NATS_CLUSTER_KV.put('cluster-nodes', JSON.stringify(filteredNodes));
    
    return new Response(JSON.stringify({
      success: true,
      nodeId: nodeId,
      cluster_size: filteredNodes.length
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to leave cluster',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

/**
 * Handle cluster status
 */
async function handleClusterStatus(request, env) {
  try {
    const clusterNodes = await env.NATS_CLUSTER_KV.get('cluster-nodes', 'json') || [];
    const activeContainers = await env.NATS_CLUSTER_KV.get('active-containers', 'json') || [];
    
    return new Response(JSON.stringify({
      cluster: {
        nodes: clusterNodes,
        size: clusterNodes.length
      },
      containers: {
        active: activeContainers,
        count: activeContainers.length
      },
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: 'Failed to get cluster status',
      message: error.message
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}
