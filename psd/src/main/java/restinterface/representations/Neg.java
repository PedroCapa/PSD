package main.java.restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Neg {
    public final String client_offer;
	public final String fab;
	public final String prod;
	public final int price;
	public final int amount;
    @JsonCreator
    public Neg(@JsonProperty("fab") String fab, @JsonProperty("client_offer") String client_offer, 
    	@JsonProperty("prod") String prod, @JsonProperty("price") int price, @JsonProperty("amount") int amount) {
      	this.fab = fab;
		this.client_offer = client_offer;
		this.prod = prod;
		this.price = price;
		this.amount = amount;
    }
}

