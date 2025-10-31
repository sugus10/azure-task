document.addEventListener('DOMContentLoaded', function() {
  // DOM elements
  const itemsList = document.getElementById('itemsList');
  const loadingElement = document.getElementById('loading');
  const errorMessage = document.getElementById('errorMessage');
  const errorText = document.getElementById('errorText');
  const emptyState = document.getElementById('emptyState');
  const itemForm = document.getElementById('itemForm');
  const itemId = document.getElementById('itemId');
  const itemName = document.getElementById('itemName');
  const itemDescription = document.getElementById('itemDescription');
  const saveItemBtn = document.getElementById('saveItemBtn');
  const addItemModal = new bootstrap.Modal(document.getElementById('addItemModal'));
  const deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));
  const deleteItemName = document.getElementById('deleteItemName');
  const confirmDeleteBtn = document.getElementById('confirmDeleteBtn');
  
  // Initialize
  loadItems();
  
  // Event listeners
  saveItemBtn.addEventListener('click', saveItem);
  confirmDeleteBtn.addEventListener('click', confirmDelete);
  
  // Reset form when modal is opened for a new item
  document.getElementById('addItemModal').addEventListener('show.bs.modal', function(event) {
    const button = event.relatedTarget;
    if (!button || !button.getAttribute('data-id')) {
      // New item
      document.getElementById('addItemModalLabel').textContent = 'Add New Item';
      itemForm.reset();
      itemId.value = '';
    }
  });
  
  // Load all items from the API
  function loadItems() {
    showLoading();
    
    fetch('/api/items')
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
      })
      .then(items => {
        hideLoading();
        if (items.length === 0) {
          showEmptyState();
        } else {
          hideEmptyState();
          renderItems(items);
        }
      })
      .catch(error => {
        hideLoading();
        showError('Failed to load items. ' + error.message);
      });
  }
  
  // Render items to the DOM
  function renderItems(items) {
    itemsList.innerHTML = '';
    itemsList.classList.remove('d-none');
    
    items.forEach(item => {
      const createdDate = new Date(item.createdAt).toLocaleDateString();
      const updatedDate = item.updatedAt ? new Date(item.updatedAt).toLocaleDateString() : null;
      
      const itemElement = document.createElement('div');
      itemElement.className = 'col';
      itemElement.innerHTML = `
        <div class="card shadow-sm item-card" data-id="${item.id}">
          <div class="card-body">
            <h5 class="card-title">${escapeHtml(item.name)}</h5>
            <p class="card-text">${escapeHtml(item.description || '')}</p>
          </div>
          <div class="card-footer bg-transparent">
            <div class="d-flex justify-content-between align-items-center">
              <small class="timestamp">Created: ${createdDate}${updatedDate ? '<br>Updated: ' + updatedDate : ''}</small>
              <div class="item-actions">
                <button class="btn btn-sm btn-outline-primary btn-icon edit-item" title="Edit">
                  <i class="bi bi-pencil"></i>
                </button>
                <button class="btn btn-sm btn-outline-danger btn-icon delete-item" title="Delete">
                  <i class="bi bi-trash"></i>
                </button>
              </div>
            </div>
          </div>
        </div>
      `;
      
      itemsList.appendChild(itemElement);
      
      // Add event listeners to the new item's buttons
      const card = itemElement.querySelector('.card');
      const editBtn = itemElement.querySelector('.edit-item');
      const deleteBtn = itemElement.querySelector('.delete-item');
      
      editBtn.addEventListener('click', () => editItem(item));
      deleteBtn.addEventListener('click', () => showDeleteModal(item));
    });
  }
  
  // Save an item (create or update)
  function saveItem() {
    if (!itemName.value.trim()) {
      alert('Name is required');
      return;
    }
    
    const id = itemId.value;
    const data = {
      name: itemName.value.trim(),
      description: itemDescription.value.trim()
    };
    
    const url = id ? `/api/items/${id}` : '/api/items';
    const method = id ? 'PUT' : 'POST';
    
    fetch(url, {
      method: method,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      return response.json();
    })
    .then(result => {
      addItemModal.hide();
      loadItems();
    })
    .catch(error => {
      showError('Failed to save item. ' + error.message);
    });
  }
  
  // Edit an item
  function editItem(item) {
    document.getElementById('addItemModalLabel').textContent = 'Edit Item';
    itemId.value = item.id;
    itemName.value = item.name;
    itemDescription.value = item.description || '';
    addItemModal.show();
  }
  
  // Show delete confirmation modal
  function showDeleteModal(item) {
    deleteItemName.textContent = item.name;
    confirmDeleteBtn.setAttribute('data-id', item.id);
    deleteModal.show();
  }
  
  // Delete an item
  function confirmDelete() {
    const id = confirmDeleteBtn.getAttribute('data-id');
    
    fetch(`/api/items/${id}`, {
      method: 'DELETE'
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      return response.json();
    })
    .then(result => {
      deleteModal.hide();
      loadItems();
    })
    .catch(error => {
      deleteModal.hide();
      showError('Failed to delete item. ' + error.message);
    });
  }
  
  // Helper functions
  function showLoading() {
    loadingElement.classList.remove('d-none');
    itemsList.classList.add('d-none');
    emptyState.classList.add('d-none');
    errorMessage.classList.add('d-none');
  }
  
  function hideLoading() {
    loadingElement.classList.add('d-none');
  }
  
  function showEmptyState() {
    emptyState.classList.remove('d-none');
    itemsList.classList.add('d-none');
  }
  
  function hideEmptyState() {
    emptyState.classList.add('d-none');
  }
  
  function showError(message) {
    errorText.textContent = message;
    errorMessage.classList.remove('d-none');
    setTimeout(() => {
      errorMessage.classList.add('d-none');
    }, 5000);
  }
  
  function escapeHtml(unsafe) {
    if (!unsafe) return '';
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
});
