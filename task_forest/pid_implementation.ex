defimpl Jason.Encoder, for: PID do
  def encode(pid, _opts) do
    pid |> inspect() |> Jason.encode!()
  end
end
