package main.java.restinterface.representations;

import com.fasterxml.jackson.annotation.*;

public class Prod {
    public final String product_name;
	public final String negotiator_name;
	public final int min;
	public final int max;
	public final int price;
    @JsonCreator
    public Prod(@JsonProperty("content") String product_name, @JsonProperty("description") String negotiator_name,
    			@JsonProperty("content") int min, @JsonProperty("description") int max,
    			@JsonProperty("content") int price) {
      	this.product_name = product_name;
		this.negotiator_name = negotiator_name;
		this.min = min;
		this.max = max;
		this.price = price;
    }
}

