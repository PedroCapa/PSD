package main.java.restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Imp {
	public final String fabricante;
	public final String prod;
	public final int price;
	public final int amount;
	public final String data;
	public final int state;
    @JsonCreator
    public Imp(@JsonProperty("fabricante") String fabricante, @JsonProperty("produto") String prod, 
			   @JsonProperty("price") int price, @JsonProperty("amount") int amount, @JsonProperty("data") String data, 
			   @JsonProperty("state") int state) {
      	this.fabricante = fabricante;
		this.prod = prod;
		this.price = price;
		this.amount = amount;
		this.data = data;
		this.state = state;
    }
}

