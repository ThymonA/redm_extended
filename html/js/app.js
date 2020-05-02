(() => {

	RDX = {};
	RDX.HUDElements = [];

	RDX.setHUDDisplay = function (opacity) {
		$('#hud').css('opacity', opacity);
	};

	RDX.insertHUDElement = function (name, index, priority, html, data) {
		RDX.HUDElements.push({
			name: name,
			index: index,
			priority: priority,
			html: html,
			data: data
		});

		RDX.HUDElements.sort((a, b) => {
			return a.index - b.index || b.priority - a.priority;
		});
	};

	RDX.updateHUDElement = function (name, data) {
		for (let i = 0; i < RDX.HUDElements.length; i++) {
			if (RDX.HUDElements[i].name == name) {
				RDX.HUDElements[i].data = data;
			}
		}

		RDX.refreshHUD();
	};

	RDX.deleteHUDElement = function (name) {
		for (let i = 0; i < RDX.HUDElements.length; i++) {
			if (RDX.HUDElements[i].name == name) {
				RDX.HUDElements.splice(i, 1);
			}
		}

		RDX.refreshHUD();
	};

	RDX.refreshHUD = function () {
		$('#hud').html('');

		for (let i = 0; i < RDX.HUDElements.length; i++) {
			let html = Mustache.render(RDX.HUDElements[i].html, RDX.HUDElements[i].data);
			$('#hud').append(html);
		}
	};

	RDX.inventoryNotification = function (add, label, count) {
		let notif = '';

		if (add) {
			notif += '+';
		} else {
			notif += '-';
		}

		if (count) {
			notif += count + ' ' + label;
		} else {
			notif += ' ' + label;
		}

		let elem = $('<div>' + notif + '</div>');
		$('#inventory_notifications').append(elem);

		$(elem).delay(3000).fadeOut(1000, function () {
			elem.remove();
		});
	};

	window.onData = (data) => {
		switch (data.action) {
			case 'setHUDDisplay': {
				RDX.setHUDDisplay(data.opacity);
				break;
			}

			case 'insertHUDElement': {
				RDX.insertHUDElement(data.name, data.index, data.priority, data.html, data.data);
				break;
			}

			case 'updateHUDElement': {
				RDX.updateHUDElement(data.name, data.data);
				break;
			}

			case 'deleteHUDElement': {
				RDX.deleteHUDElement(data.name);
				break;
			}

			case 'inventoryNotification': {
				RDX.inventoryNotification(data.add, data.item, data.count);
			}
		}
	};

	window.addEventListener('message', function(event) {
		onData(event.data);
	});
})();