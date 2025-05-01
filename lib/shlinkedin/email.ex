defmodule Shlinkedin.Email do
  import Bamboo.Email

  def new_email(to, subject, body) do
    new_email(
      to: to,
      from: "melivra@gmail.com",
      subject: subject,
      html_body: body
    )
  end

  def user_email(to, subject, body) do
    new_email(
      to: to,
      from: "melivra@gmail.com",
      subject: "MeLivra -- #{subject}",
      html_body: body,
      text_body: body
    )
  end
end
