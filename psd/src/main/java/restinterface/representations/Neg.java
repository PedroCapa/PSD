package main.java.restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Neg {
	public final String username;
	public final int price;
	public final int amount;
	public final String data;
	public final int state;
    @JsonCreator
    public Neg(@JsonProperty("username") String username, @JsonProperty("price") int price, 
    	@JsonProperty("amount") int amount, @JsonProperty("data") String data, @JsonProperty("state") int state) {
      	this.username = username;
		this.price = price;
		this.amount = amount;
		this.data = data;
		this.state = state;
    }
}

