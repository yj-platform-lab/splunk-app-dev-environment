require(['jquery', 'splunkjs/mvc', 'splunkjs/mvc/simplexml/ready!'], function ($, mvc) {
    'use strict';

    var root = $('#album-lab-root');
    var service = mvc.createService();
    var endpoint = '/services/album_lab/albums';

    var form = $('<form>');
    var albumName = $('<input>', {type: 'text', maxlength: 255, required: true,
        placeholder: 'Album name', 'aria-label': 'Album name'});
    var artistName = $('<input>', {type: 'text', maxlength: 255, required: true,
        placeholder: 'Artist name', 'aria-label': 'Artist name'});
    var button = $('<button>', {type: 'submit', text: 'Save album'});
    var message = $('<p>', {'role': 'status'});
    var table = $('<table>').append(
        $('<thead>').append($('<tr>').append(
            $('<th>').text('ID'), $('<th>').text('Album'),
            $('<th>').text('Artist'), $('<th>').text('Created at'),
            $('<th>').text('Action')
        )), $('<tbody>')
    );
    var tbody = table.find('tbody');

    form.append(albumName, artistName, button);
    root.append($('<h2>').text('Add an album'), form, message,
        $('<h2>').text('Saved albums'), table);

    function payload(response) {
        var data = response.data;
        if (typeof data === 'string') {
            data = JSON.parse(data);
        }
        data = data.data || data;
        return typeof data === 'string' ? JSON.parse(data) : data;
    }

    function loadAlbums() {
        service.get(endpoint, {output_mode: 'json'}, function (error, response) {
            if (error) {
                message.text('Could not load albums.');
                return;
            }
            try {
                var albums = payload(response).albums;
                tbody.empty();
                albums.forEach(function (album) {
                    var deleteButton = $('<button>', {type: 'button', text: 'Delete',
                        'aria-label': 'Delete ' + album.album_name});
                    deleteButton.on('click', function () {
                        if (!window.confirm('Delete "' + album.album_name + '"?')) {
                            return;
                        }
                        deleteButton.prop('disabled', true);
                        message.text('Deleting...');
                        service.post(endpoint, {
                            action: 'delete', id: album.id, output_mode: 'json'
                        }, function (error) {
                            deleteButton.prop('disabled', false);
                            if (error) {
                                message.text('Could not delete the album.');
                                return;
                            }
                            message.text('Album deleted.');
                            loadAlbums();
                        });
                    });
                    tbody.append($('<tr>').append(
                        $('<td>').text(album.id),
                        $('<td>').text(album.album_name),
                        $('<td>').text(album.artist_name),
                        $('<td>').text(album.created_at),
                        $('<td>').append(deleteButton)
                    ));
                });
            } catch (exc) {
                message.text('Could not read the album response.');
            }
        });
    }

    form.on('submit', function (event) {
        event.preventDefault();
        button.prop('disabled', true);
        message.text('Saving...');
        service.post(endpoint, {
            album_name: albumName.val().trim(),
            artist_name: artistName.val().trim(),
            output_mode: 'json'
        }, function (error) {
            button.prop('disabled', false);
            if (error) {
                message.text('Could not save the album.');
                return;
            }
            albumName.val('');
            artistName.val('');
            message.text('Album saved.');
            loadAlbums();
        });
    });

    loadAlbums();
});
