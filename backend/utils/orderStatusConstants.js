/**
 * Order Status Constants and Workflow Definitions
 */

const ORDER_TYPES = {
    ONLINE: 'ONLINE',
    DINING: 'DINING',
    TAKEAWAY: 'TAKEAWAY'
};

const ORDER_STATUS = {
    PLACED: 'PLACED',
    CONFIRMED: 'CONFIRMED',
    PREPARING: 'PREPARING',
    READY: 'READY',
    READY_FOR_PICKUP: 'READY_FOR_PICKUP',
    SERVED: 'SERVED',
    OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
    DELIVERED: 'DELIVERED',
    COMPLETED: 'COMPLETED',
    CANCELLED: 'CANCELLED',
    // Legacy support
    WAITING_PAYMENT: 'WAITING_PAYMENT'
};

const WORKFLOWS = {
    [ORDER_TYPES.ONLINE]: [
        ORDER_STATUS.PLACED,
        ORDER_STATUS.CONFIRMED,
        ORDER_STATUS.PREPARING,
        ORDER_STATUS.READY,
        ORDER_STATUS.OUT_FOR_DELIVERY,
        ORDER_STATUS.DELIVERED
    ],
    [ORDER_TYPES.DINING]: [
        ORDER_STATUS.PLACED,
        ORDER_STATUS.CONFIRMED,
        ORDER_STATUS.PREPARING,
        ORDER_STATUS.READY,
        ORDER_STATUS.SERVED,
        ORDER_STATUS.COMPLETED
    ],
    [ORDER_TYPES.TAKEAWAY]: [
        ORDER_STATUS.PLACED,
        ORDER_STATUS.CONFIRMED,
        ORDER_STATUS.PREPARING,
        ORDER_STATUS.READY_FOR_PICKUP,
        ORDER_STATUS.COMPLETED
    ]
};

/**
 * Get allowed next statuses based on current status and order type
 */
const getAllowedStatuses = (orderType, currentStatus) => {
    const workflow = WORKFLOWS[orderType] || WORKFLOWS[ORDER_TYPES.ONLINE];
    const currentIndex = workflow.indexOf(currentStatus);
    
    if (currentIndex === -1) return []; // Unknown status or cancelled
    if (currentIndex === workflow.length - 1) return []; // Final status reached
    
    // Return all subsequent statuses or just the next one? 
    // Usually in a POS, you can skip but it's better to guide.
    return workflow.slice(currentIndex + 1);
};

module.exports = {
    ORDER_TYPES,
    ORDER_STATUS,
    WORKFLOWS,
    getAllowedStatuses
};
