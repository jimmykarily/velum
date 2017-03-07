MinionPoller = {
  poll: function() {
    this.masterAlreadyExists = $(".nodes-container table").data("masterExists");
    this.request();
    return setInterval(this.request, 5000);
  },

  request: function() {
    $.ajax({
      url: $('#nodes').data('url'),
      dataType: "json",
      success: function(data) {
        var rendered = "";

        for (i = 0; i < data.length; i++) {
            rendered += MinionPoller.render(data[i]);
        }
        $(".nodes-container tbody").html(rendered);
      }
    });
  },

  render: function(minion) {
    switch(minion.highstate) {
      case "not_applied":
        statusHtml = '<i class="fa fa-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
      case "pending":
        statusHtml = '\
          <span class="fa-stack" aria-hidden="true">\
            <i class="fa fa-circle fa-stack-2x text-success" aria-hidden="true"></i>\
            <i class="fa fa-refresh fa-stack-1x fa-spin fa-inverse" aria-hidden="true"></i>\
          </span>';
        break;
      case "failed":
        statusHtml = '<i class="fa fa-times-circle text-danger fa-2x" aria-hidden="true"></i>';
        break;
      case "applied":
        statusHtml = '<i class="fa fa-check-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
    } 

    disabled = this.masterAlreadyExists ? "disabled=''" : "";
    checked = minion.role == "master" ? "checked" : "";
    masterHtml = '<input name="roles[master]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="radio" ' + disabled + ' ' + checked + '>';

    return "\
      <tr> \
        <th>" + minion.id +  "</th>\
        <td class='text-center'>" + statusHtml +  "</td>\
        <td>" + minion.hostname +  "</td>\
        <td>" + (minion.role || '') +  "</td>\
        <td class='text-center'>" + masterHtml + "</td>\
      </tr>";
  }
};
